# ──────────────────────────────────────────────────────────────────────────────
# _ssh_key — Outputs
# ──────────────────────────────────────────────────────────────────────────────

output "ssh_key_id" {
  description = "ID of the Hetzner SSH key."
  value       = try(hcloud_ssh_key.this["this"].id, null)
}

# DECISION: Output named private_key_openssh to match the actual format.
# Why: tls_private_key.private_key_openssh produces OpenSSH format, not PEM.
#      Naming it _pem would mislead consumers about the encoding.
output "private_key_openssh" {
  description = "OpenSSH-encoded private key. Only populated when the key was auto-generated."
  value       = try(tls_private_key.this["this"].private_key_openssh, "")
  sensitive   = true
}

output "public_key_openssh" {
  description = "OpenSSH-formatted public key."
  value       = try(tls_private_key.this["this"].public_key_openssh, var.public_key)
}
