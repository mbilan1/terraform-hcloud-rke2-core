# ──────────────────────────────────────────────────────────────────────────────
# _control_plane — Outputs
#
# NOTE: Outputs merge data from both hcloud_server.initial (the bootstrap node)
#       and hcloud_server.joining (all other control plane nodes) to present a
#       unified map keyed by node name.
# ──────────────────────────────────────────────────────────────────────────────

output "server_ids" {
  description = "Map of node key to Hetzner server ID."
  value = merge(
    { for k, v in hcloud_server.initial : k => v.id },
    { for k, v in hcloud_server.joining : k => v.id }
  )
}

output "server_ipv4_addresses" {
  description = "Map of node key to public IPv4 address."
  value = merge(
    { for k, v in hcloud_server.initial : k => v.ipv4_address },
    { for k, v in hcloud_server.joining : k => v.ipv4_address }
  )
}

output "server_private_ipv4_addresses" {
  description = "Map of node key to private IPv4 address."
  value = merge(
    { for k, v in hcloud_server_network.initial : k => v.ip },
    { for k, v in hcloud_server_network.joining : k => v.ip }
  )
}

output "initial_master_key" {
  description = "Key of the initial master node (cluster bootstrap node)."
  value       = var.create ? local.initial_master : null
}

output "initial_master_ipv4" {
  description = "Public IPv4 address of the initial master node."
  value       = try(hcloud_server.initial[local.initial_master].ipv4_address, null)
}

output "initial_master_private_ipv4" {
  description = "Private IPv4 address of the initial master node."
  value       = try(hcloud_server_network.initial[local.initial_master].ip, null)
}
