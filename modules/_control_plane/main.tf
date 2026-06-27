# ──────────────────────────────────────────────────────────────────────────────
# _control_plane — Server Instances Primitive
#
# DECISION: for_each over map(object) instead of count.
# Why: Count-based servers are ordered — removing server [1] from a list of 3
#      forces [2] to be destroyed and recreated. Map keys are stable
#      identifiers: removing "cp-1" only destroys that one server.
# See: docs/ARCHITECTURE.md — Node Identity
#
# DECISION: Initial master split from joining nodes into separate resources.
# Why: Joining nodes need the initial master's private IP in their cloud-init
#      (server: https://<ip>:9345). The private IP is only known after the
#      initial master's hcloud_server_network is created. Splitting into
#      two resources makes this dependency explicit and correct — joining
#      nodes wait for the initial master to be fully networked.
#
# DECISION: Cloud-init via templatefile(), not the cloudinit provider.
# Why: The cloudinit provider adds a dependency for minimal benefit. Raw
#      templatefile() with a YAML template is simpler, produces readable
#      plans, and eliminates one provider from the dependency tree.
# ──────────────────────────────────────────────────────────────────────────────

locals {
  # DECISION: Deterministic initial master selection via sorted keys.
  # Why: The first node (alphabetically) bootstraps the cluster. All others
  #      join it. Using sort() ensures deterministic behavior regardless of
  #      map iteration order (which is already alphabetical in HCL, but
  #      being explicit avoids surprises).
  sorted_node_keys = sort(keys(var.nodes))
  initial_master   = local.sorted_node_keys[0]

  # DECISION: Joining nodes computed once for reuse in resources and outputs.
  # Why: Avoids duplicating the filter expression. Single source of truth for
  #      which nodes are joining vs initial.
  joining_nodes = { for k, v in var.nodes : k => v if k != local.initial_master }

  # DECISION: Common labels merged with per-node labels.
  # Why: Cluster-wide labels (managed-by, cluster-name) apply to all nodes.
  #      Per-node labels (role-specific, custom) override cluster-wide ones.
  # NOTE: var.labels already contains cluster + managed-by from the root facade.
  # Only add the role label here — avoid re-declaring keys that the facade owns.
  common_labels = merge(var.labels, {
    "role" = "control-plane"
  })
}

# ─── Initial Master ───────────────────────────────────────────────────────────

# NOTE: The initial master bootstraps the cluster. It is created first so that
#       its private IP can be passed to joining nodes' cloud-init config.
#
# DECISION: The initial node is re-provisionable as a joining RKE2 server.
# Why: Re-creating the initial node with is_initial=true would re-run
#      cluster-init and create a NEW empty etcd — a data-loss SPOF. With
#      control_plane_bootstrap_complete=true the initial node renders
#      is_initial=false and points its server at a surviving CP peer, so it
#      joins the existing etcd quorum on rebuild/OS-migration. On the very
#      first genesis apply the flag is false so this node bootstraps the
#      cluster. NO load balancer is involved — peer join is by private IP.
# Why: RKE2 ignores the server field when an etcd datastore already exists on
#      disk, so a healthy initial node is unaffected; only a fresh disk joins.
# See: ADR-016 L3a in rke2-hetzner-architecture
resource "hcloud_server" "initial" {
  for_each = var.create ? { (local.initial_master) = var.nodes[local.initial_master] } : {}

  name         = "${var.cluster_name}-${each.key}"
  server_type  = each.value.server_type
  location     = coalesce(each.value.location, var.hcloud_location)
  image        = var.hcloud_image
  ssh_keys     = var.ssh_key_ids
  backups      = each.value.backups
  firewall_ids = var.firewall_ids

  user_data = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    hostname                  = "${var.cluster_name}-${each.key}"
    is_initial                = !var.control_plane_bootstrap_complete
    rke2_version              = var.rke2_version
    rke2_config               = var.rke2_config
    enable_cis                = var.enable_cis
    cis_psa_exempt_namespaces = var.cis_psa_exempt_namespaces
    cluster_token             = var.cluster_token
    join_address              = var.control_plane_bootstrap_complete ? var.control_plane_bootstrap_join_address : ""
    extra_server_manifests    = var.extra_server_manifests
  })

  delete_protection  = var.delete_protection
  rebuild_protection = var.delete_protection

  labels = merge(local.common_labels, each.value.labels)

  # COMPROMISE: ignore_changes on user_data.
  # Why: Cloud-init runs once at boot. Changing user_data forces server
  #      replacement, which is destructive for stateful control plane nodes.
  #      Config changes should be applied via RKE2 config management, not
  #      server replacement.
  # TODO: Remove if Hetzner adds in-place user_data update capability.
  lifecycle {
    ignore_changes = [
      user_data,
      ssh_keys,
      image,
    ]
  }
}

# ─── Initial Master Network Attachment ────────────────────────────────────────

resource "hcloud_server_network" "initial" {
  # DECISION: Iterate a projected id-only map, not the whole server objects.
  # Why: for_each over hcloud_server.* carries the resource's deprecated computed
  #      attributes (datacenter / allow_deprecated_images / backup_window), so
  #      OpenTofu emits "Value derived from a deprecated source" on every plan/test
  #      even though only .id is consumed here. The hcloud `datacenter` attribute is
  #      removed after 2026-07-01. Projecting to the id keeps a stable key and
  #      surfaces no deprecated fields (warning-free, removal-proof).
  # See: https://docs.hetzner.cloud/changelog#2025-12-16-phasing-out-datacenters
  for_each = { for k, v in hcloud_server.initial : k => v.id }

  server_id  = each.value
  network_id = var.network_id
}

# ─── Joining Nodes ────────────────────────────────────────────────────────────

resource "hcloud_server" "joining" {
  for_each = var.create ? local.joining_nodes : {}

  name         = "${var.cluster_name}-${each.key}"
  server_type  = each.value.server_type
  location     = coalesce(each.value.location, var.hcloud_location)
  image        = var.hcloud_image
  ssh_keys     = var.ssh_key_ids
  backups      = each.value.backups
  firewall_ids = var.firewall_ids

  user_data = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    hostname                  = "${var.cluster_name}-${each.key}"
    is_initial                = false
    rke2_version              = var.rke2_version
    rke2_config               = var.rke2_config
    enable_cis                = var.enable_cis
    cis_psa_exempt_namespaces = var.cis_psa_exempt_namespaces
    cluster_token             = var.cluster_token
    # DECISION: Join via initial master's private IP from network attachment.
    # Why: Using private IP keeps supervisor API traffic on the private network.
    #      The IP is reliably known because hcloud_server_network.initial is
    #      created before joining nodes due to the implicit dependency.
    join_address           = hcloud_server_network.initial[local.initial_master].ip
    extra_server_manifests = var.extra_server_manifests
  })

  delete_protection  = var.delete_protection
  rebuild_protection = var.delete_protection

  labels = merge(local.common_labels, each.value.labels)

  lifecycle {
    ignore_changes = [
      user_data,
      ssh_keys,
      image,
    ]
  }
}

# ─── Joining Nodes Network Attachment ─────────────────────────────────────────

resource "hcloud_server_network" "joining" {
  # See hcloud_server_network.initial — project to an id-only map so for_each does
  # not surface the deprecated hcloud_server computed attributes.
  for_each = { for k, v in hcloud_server.joining : k => v.id }

  server_id  = each.value
  network_id = var.network_id
}
