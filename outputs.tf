# ──────────────────────────────────────────────────────────────────────────────
# OUTPUTS — Flat grouped outputs from facade submodules
#
# DECISION: Output naming follows {group}_{attribute} convention.
# Why: Consistent naming makes outputs predictable and greppable.
#      No "this_" prefix — following terraform-skill convention.
#
# DECISION: try() wraps all submodule references.
# Why: When var.create = false, submodule outputs may be null. try() prevents
#      failures and returns clean empty/null values instead of runtime errors.
# ──────────────────────────────────────────────────────────────────────────────

# ─── Network ──────────────────────────────────────────────────────────────────

output "network_id" {
  description = "ID of the private network (created or BYO)."
  value       = try(module.network.network_id, null)
}

output "network_subnet_id" {
  description = "ID of the subnet."
  value       = try(module.network.subnet_id, null)
}

# ─── Firewall ─────────────────────────────────────────────────────────────────

output "firewall_control_plane_ids" {
  description = "Firewall IDs attached to control plane nodes."
  value       = try(module.firewall.control_plane_firewall_ids, [])
}

output "firewall_worker_ids" {
  description = "Firewall IDs attached to worker nodes."
  value       = try(module.firewall.worker_firewall_ids, [])
}

# ─── SSH ──────────────────────────────────────────────────────────────────────

output "ssh_key_id" {
  description = "ID of the Hetzner SSH key."
  value       = try(module.ssh_key.ssh_key_id, null)
}

output "ssh_private_key" {
  description = "Auto-generated SSH private key (empty when BYO key is used)."
  value       = try(module.ssh_key.private_key_pem, "")
  sensitive   = true
}

output "ssh_public_key" {
  description = "SSH public key (auto-generated or BYO)."
  value       = try(module.ssh_key.public_key_openssh, "")
}

# ─── Control Plane ────────────────────────────────────────────────────────────

output "control_plane_server_ids" {
  description = "Map of node key to Hetzner server ID for control plane nodes."
  value       = try(module.control_plane.server_ids, {})
}

output "control_plane_ipv4_addresses" {
  description = "Map of node key to public IPv4 address for control plane nodes."
  value       = try(module.control_plane.server_ipv4_addresses, {})
}

output "control_plane_private_ipv4_addresses" {
  description = "Map of node key to private IPv4 address for control plane nodes."
  value       = try(module.control_plane.server_private_ipv4_addresses, {})
}

output "initial_master_ipv4" {
  description = "Public IPv4 address of the initial master (cluster bootstrap node)."
  value       = try(module.control_plane.initial_master_ipv4, null)
}

# ─── Cluster State ────────────────────────────────────────────────────────────

output "cluster_token" {
  description = "RKE2 cluster registration token."
  value       = try(random_password.cluster_token[0].result, "")
  sensitive   = true
}

output "cluster_ready" {
  description = "Boolean indicating the cluster API server is responsive."
  value       = try(module.readiness.cluster_ready, false)
}
