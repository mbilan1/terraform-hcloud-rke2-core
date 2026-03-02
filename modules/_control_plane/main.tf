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
  common_labels = merge(var.labels, {
    "cluster"    = var.cluster_name
    "managed-by" = "opentofu"
    "role"       = "control-plane"
  })
}

# ─── Initial Master ───────────────────────────────────────────────────────────

# NOTE: The initial master bootstraps the cluster. It is created first so that
#       its private IP can be passed to joining nodes' cloud-init config.
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
    hostname      = "${var.cluster_name}-${each.key}"
    is_initial    = true
    rke2_version  = var.rke2_version
    rke2_config   = var.rke2_config
    cluster_token = var.cluster_token
    join_address  = ""
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
  for_each = hcloud_server.initial

  server_id  = each.value.id
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
    hostname      = "${var.cluster_name}-${each.key}"
    is_initial    = false
    rke2_version  = var.rke2_version
    rke2_config   = var.rke2_config
    cluster_token = var.cluster_token
    # DECISION: Join via initial master's private IP from network attachment.
    # Why: Using private IP keeps supervisor API traffic on the private network.
    #      The IP is reliably known because hcloud_server_network.initial is
    #      created before joining nodes due to the implicit dependency.
    join_address = hcloud_server_network.initial[local.initial_master].ip
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
  for_each = hcloud_server.joining

  server_id  = each.value.id
  network_id = var.network_id
}
