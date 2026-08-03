# ──────────────────────────────────────────────────────────────────────────────
# _agent — Worker Node Primitive
#
# DECISION: for_each over map(object) instead of count.
# Why: Same stable-identity reasoning as _control_plane — removing "worker-0"
#      from a list of three must not recreate the other two.
# See: docs/ARCHITECTURE.md — Node Identity
#
# DECISION: Agents take join_address as an input instead of computing it.
# Why: An agent must never bootstrap a cluster. Requiring the caller to supply a
#      control-plane private IP makes it structurally impossible for this module
#      to create a second, empty etcd — the data-loss failure mode ADR-016
#      guards against on the control-plane side.
#
# DECISION: No extra_server_manifests input.
# Why: RKE2 only reads /var/lib/rancher/rke2/server/manifests on server nodes.
#      Accepting manifests here would silently do nothing.
# ──────────────────────────────────────────────────────────────────────────────

locals {
  # NOTE: var.labels already carries cluster + managed-by from the root facade.
  # Only the role label is added here — the facade owns the rest.
  common_labels = merge(var.labels, {
    "role" = "agent"
  })
}

resource "hcloud_server" "agent" {
  for_each = var.create ? var.nodes : {}

  name         = "${var.cluster_name}-${each.key}"
  server_type  = each.value.server_type
  location     = coalesce(each.value.location, var.hcloud_location)
  image        = var.hcloud_image
  ssh_keys     = var.ssh_key_ids
  backups      = each.value.backups
  firewall_ids = var.firewall_ids

  user_data = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    hostname      = "${var.cluster_name}-${each.key}"
    rke2_version  = var.rke2_version
    rke2_config   = var.rke2_config
    enable_cis    = var.enable_cis
    cluster_token = var.cluster_token
    join_address  = var.join_address
    node_labels   = each.value.node_labels
    node_taints   = each.value.node_taints
  })

  delete_protection  = var.delete_protection
  rebuild_protection = var.delete_protection

  labels = merge(local.common_labels, each.value.labels)

  # COMPROMISE: ignore_changes on user_data.
  # Why: Cloud-init runs once at boot; changing user_data forces replacement.
  # NOTE: An agent is stateless, so replacement is cheap here — unlike a
  #       control-plane node. Rotating an agent to pick up new cloud-init is a
  #       legitimate operation: `tofu apply -replace`.
  lifecycle {
    ignore_changes = [
      user_data,
      ssh_keys,
      image,
    ]
  }
}

resource "hcloud_server_network" "agent" {
  # See _control_plane — project to an id-only map so for_each does not surface
  # the deprecated hcloud_server computed attributes (datacenter et al.).
  for_each = { for k, v in hcloud_server.agent : k => v.id }

  server_id  = each.value
  network_id = var.network_id
}
