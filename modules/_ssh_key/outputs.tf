# ──────────────────────────────────────────────────────────────────────────────
# _ssh_key — Outputs
# ──────────────────────────────────────────────────────────────────────────────

output "ssh_key_id" {
  description = "ID of the Hetzner SSH key."
  value       = try(hcloud_ssh_key.this[0].id, null)
}

output "private_key_pem" {
  description = "PEM-encoded private key. Only populated when the key was auto-generated."
  value       = try(tls_private_key.this[0].private_key_openssh, "")
  sensitive   = true
}

output "public_key_openssh" {
  description = "OpenSSH-formatted public key."
  value       = try(tls_private_key.this[0].public_key_openssh, var.public_key)
}
