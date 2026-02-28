# ──────────────────────────────────────────────────────────────────────────────
# _control_plane — Server Instances Primitive
#
# DECISION: for_each over map(object) instead of count.
# Why: Count-based servers are ordered — removing server [1] from a list of 3
#      forces [2] to be destroyed and recreated. Map keys are stable
#      identifiers: removing "cp-1" only destroys that one server.
# See: docs/ARCHITECTURE.md — Node Identity
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

  # DECISION: Common labels merged with per-node labels.
  # Why: Cluster-wide labels (managed-by, cluster-name) apply to all nodes.
  #      Per-node labels (role-specific, custom) override cluster-wide ones.
  common_labels = merge(var.labels, {
    "cluster"    = var.cluster_name
    "managed-by" = "opentofu"
    "role"       = "control-plane"
  })
}

# ─── Server Instances ─────────────────────────────────────────────────────────

resource "hcloud_server" "this" {
  for_each = var.create ? var.nodes : {}

  name        = "${var.cluster_name}-${each.key}"
  server_type = each.value.server_type
  location    = coalesce(each.value.location, var.location)
  image       = var.image
  ssh_keys    = var.ssh_key_ids
  labels      = merge(local.common_labels, each.value.labels)
  backups     = each.value.backups

  firewall_ids = var.firewall_ids

  user_data = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    hostname       = "${var.cluster_name}-${each.key}"
    is_initial     = each.key == local.initial_master
    rke2_version   = var.rke2_version
    rke2_config    = var.rke2_config
    cluster_token  = var.cluster_token
    initial_master = "${var.cluster_name}-${local.initial_master}"
    # DECISION: Join address uses private IP of the initial master.
    # Why: Joining via public IP would expose the supervisor API to the
    #      internet and add latency. Private networking is always configured.
    join_address = each.key == local.initial_master ? "" : "RESOLVE_AT_BOOT"
    ssh_port     = var.ssh_port
  })

  delete_protection  = var.delete_protection
  rebuild_protection = var.delete_protection

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

# ─── Network Attachment ───────────────────────────────────────────────────────

resource "hcloud_server_network" "this" {
  for_each = var.create ? var.nodes : {}

  server_id  = hcloud_server.this[each.key].id
  network_id = var.network_id
}
