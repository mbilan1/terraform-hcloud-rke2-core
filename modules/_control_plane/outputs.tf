# ──────────────────────────────────────────────────────────────────────────────
# _control_plane — Outputs
# ──────────────────────────────────────────────────────────────────────────────

output "server_ids" {
  description = "Map of node key to Hetzner server ID."
  value       = { for k, v in hcloud_server.this : k => v.id }
}

output "server_ipv4_addresses" {
  description = "Map of node key to public IPv4 address."
  value       = { for k, v in hcloud_server.this : k => v.ipv4_address }
}

output "server_private_ipv4_addresses" {
  description = "Map of node key to private IPv4 address."
  value       = { for k, v in hcloud_server_network.this : k => v.ip }
}

output "initial_master_key" {
  description = "Key of the initial master node (cluster bootstrap node)."
  value       = var.create ? local.initial_master : null
}

output "initial_master_ipv4" {
  description = "Public IPv4 address of the initial master node."
  value       = var.create ? hcloud_server.this[local.initial_master].ipv4_address : null
}

output "initial_master_private_ipv4" {
  description = "Private IPv4 address of the initial master node."
  value       = var.create ? hcloud_server_network.this[local.initial_master].ip : null
}
