# ──────────────────────────────────────────────────────────────────────────────
# _network — Outputs
#
# DECISION: Output naming follows terraform-skill convention: {name}_{attribute}.
# Why: Consistent naming makes outputs predictable and greppable across modules.
# ──────────────────────────────────────────────────────────────────────────────

output "network_id" {
  description = "ID of the network (created or existing)."
  value       = try(hcloud_network.this[0].id, var.existing_network_id)
}

output "subnet_id" {
  description = "ID of the created subnet. Null when using an existing network."
  value       = try(hcloud_network_subnet.this[0].id, null)
}

output "network_ip_range" {
  description = "IP range of the network."
  value       = try(hcloud_network.this[0].ip_range, var.ip_range)
}
