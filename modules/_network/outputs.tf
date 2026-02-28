# ──────────────────────────────────────────────────────────────────────────────
# _network — Outputs
#
# DECISION: Output naming follows terraform-skill convention: {name}_{attribute}.
# Why: Consistent naming makes outputs predictable and greppable across modules.
# ──────────────────────────────────────────────────────────────────────────────

output "network_id" {
  description = "ID of the network (created or existing)."
  value       = try(hcloud_network.this["this"].id, var.existing_network_id)
}

output "subnet_id" {
  description = "ID of the created subnet. Null when using an existing network."
  value       = try(hcloud_network_subnet.this["this"].id, null)
}

output "hcloud_network_cidr" {
  description = "IP range of the network."
  value       = try(hcloud_network.this["this"].ip_range, var.ip_range)
}
