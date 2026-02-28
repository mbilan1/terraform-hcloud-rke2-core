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
  count = local.create_key ? 1 : 0

  algorithm = "ED25519"
}

# ─── Hetzner SSH Key ─────────────────────────────────────────────────────────

resource "hcloud_ssh_key" "this" {
  count = var.create ? 1 : 0

  name       = "${var.name}-ssh-key"
  public_key = local.create_key ? tls_private_key.this[0].public_key_openssh : var.public_key
  labels     = var.labels
}
