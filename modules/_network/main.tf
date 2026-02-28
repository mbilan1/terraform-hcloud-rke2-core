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
  count = local.create_network ? 1 : 0

  name     = "${var.name}-network"
  ip_range = var.ip_range
  labels   = var.labels

  delete_protection = var.delete_protection

  lifecycle {
    # NOTE: Changing ip_range requires network recreation, which destroys all
    #       attached subnets and server network attachments. Prevent accidental
    #       changes in production.
    prevent_destroy = false
  }
}

# ─── Subnet ──────────────────────────────────────────────────────────────────

resource "hcloud_network_subnet" "this" {
  count = local.create_network ? 1 : 0

  network_id   = hcloud_network.this[0].id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = var.subnet_ip_range
}

# ─── Outputs ──────────────────────────────────────────────────────────────────
# NOTE: Outputs are in outputs.tf per terraform-skill file layout convention.
