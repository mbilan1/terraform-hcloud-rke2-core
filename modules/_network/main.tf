# ──────────────────────────────────────────────────────────────────────────────
# _network — Private Network Primitive
#
# DECISION: BYO pattern — create or import an existing network.
# Why: Production teams often have pre-existing network topologies and IP
#      address plans. Forcing a new network breaks multi-cluster setups.
#      When existing_network_id is set, this module creates nothing.
# See: docs/ARCHITECTURE.md — BYO Resources
# ──────────────────────────────────────────────────────────────────────────────

locals {
  # DECISION: Derive create flag from existing_network_id presence.
  # Why: Avoids a separate boolean variable — the presence of an existing ID
  #      is the signal to skip creation. Simpler API for the user.
  create_network = var.create && var.existing_network_id == null
}

# ─── Network ──────────────────────────────────────────────────────────────────

resource "hcloud_network" "this" {
  for_each = local.create_network ? { this = true } : {}

  name     = "${var.name}-network"
  ip_range = var.ip_range

  delete_protection = var.delete_protection

  labels = var.labels
}

# ─── Subnet ──────────────────────────────────────────────────────────────────

resource "hcloud_network_subnet" "this" {
  for_each = hcloud_network.this

  network_id   = each.value.id
  type         = "cloud"
  network_zone = var.hcloud_network_zone
  ip_range     = var.subnet_address
}

# ─── Outputs ──────────────────────────────────────────────────────────────────
# NOTE: Outputs are in outputs.tf per terraform-skill file layout convention.
