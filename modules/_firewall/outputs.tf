# ──────────────────────────────────────────────────────────────────────────────
# _firewall — Outputs
# ──────────────────────────────────────────────────────────────────────────────

output "control_plane_firewall_ids" {
  description = "Firewall IDs for the control plane role (created or existing)."
  value = (
    local.create_control_plane_fw
    ? [hcloud_firewall.control_plane["this"].id]
    : var.existing_control_plane_firewall_ids
  )
}

output "worker_firewall_ids" {
  description = "Firewall IDs for the worker role (created or existing)."
  value = (
    local.create_worker_fw
    ? [hcloud_firewall.worker["this"].id]
    : var.existing_worker_firewall_ids
  )
}
