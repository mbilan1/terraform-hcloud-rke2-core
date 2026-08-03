# ──────────────────────────────────────────────────────────────────────────────
# _agent — Outputs
#
# NOTE: Maps keyed by node identifier, mirroring _control_plane, so consumers
#       can address a specific agent without relying on list ordering.
# ──────────────────────────────────────────────────────────────────────────────

output "server_ids" {
  description = "Map of agent node key => Hetzner server ID."
  value       = { for k, v in hcloud_server.agent : k => v.id }
}

output "server_ipv4_addresses" {
  description = "Map of agent node key => public IPv4 address."
  value       = { for k, v in hcloud_server.agent : k => v.ipv4_address }
}

output "server_private_ipv4_addresses" {
  description = "Map of agent node key => private IPv4 address on the cluster network."
  value       = { for k, v in hcloud_server_network.agent : k => v.ip }
}
