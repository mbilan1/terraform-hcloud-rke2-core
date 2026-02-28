# ──────────────────────────────────────────────────────────────────────────────
# _ssh_key — SSH Key Pair Primitive
#
# DECISION: Auto-generate ED25519 key when no public key is provided (BYO).
# Why: Reduces setup friction for new users while allowing production teams
#      to bring their own keys. ED25519 is preferred over RSA for its
#      stronger security at smaller key sizes.
# ──────────────────────────────────────────────────────────────────────────────

locals {
  create_key = var.create && var.public_key == ""
}

# ─── Generated Key Pair ──────────────────────────────────────────────────────

resource "tls_private_key" "this" {
  for_each = local.create_key ? { this = true } : {}

  algorithm = "ED25519"
}

# ─── Hetzner SSH Key ─────────────────────────────────────────────────────────

resource "hcloud_ssh_key" "this" {
  for_each = var.create ? { this = true } : {}

  name       = "${var.name}-ssh-key"
  public_key = local.create_key ? tls_private_key.this["this"].public_key_openssh : var.public_key

  labels = var.labels
}
