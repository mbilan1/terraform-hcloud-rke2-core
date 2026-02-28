# ──────────────────────────────────────────────────────────────────────────────
# FACADE — Root Module Orchestration
#
# DECISION: Root module is a thin facade calling 5 independent primitives.
# Why: Each primitive (_network, _firewall, _ssh_key, _control_plane,
#      _readiness) is independently usable and testable. The facade wires
#      them together with sensible defaults, handling the dependency chain:
#      network → firewall → ssh_key → control_plane → readiness.
# See: docs/ARCHITECTURE.md — Module Composition
#
# DECISION: Submodule names prefixed with _ to signal "internal" usage.
# Why: Follows terraform-skill convention — underscore prefix communicates
#      that these modules are implementation details of the parent module,
#      not public API. Users should consume the root facade, not individual
#      primitives (though they CAN for advanced use cases).
# ──────────────────────────────────────────────────────────────────────────────

# ─── Computed Values ──────────────────────────────────────────────────────────

locals {
  # DECISION: Common labels defined once, composed from variables.
  # Why: Avoids label duplication across module calls. Central definition
  #      ensures consistency and makes audit/search trivial.
  common_labels = merge(var.labels, {
    "cluster"    = var.cluster_name
    "managed-by" = "opentofu"
  })
}

# ─── Cluster Token ────────────────────────────────────────────────────────────

# DECISION: Token generated in facade, not in _control_plane.
# Why: The token is a shared secret between control plane and workers.
#      Generating it in the facade makes it available to both without
#      creating a dependency between the two compute modules.
resource "random_password" "cluster_token" {
  count = var.create ? 1 : 0

  length  = 64
  special = false
}

# ─── Network ──────────────────────────────────────────────────────────────────

module "network" {
  source = "./modules/_network"

  create              = var.create
  name                = var.cluster_name
  ip_range            = var.network_ip_range
  subnet_ip_range     = var.subnet_ip_range
  network_zone        = var.network_zone
  existing_network_id = var.existing_network_id
  delete_protection   = var.delete_protection
  labels              = local.common_labels
}

# ─── Firewall ─────────────────────────────────────────────────────────────────

module "firewall" {
  source = "./modules/_firewall"

  create            = var.create
  name              = var.cluster_name
  ssh_port          = var.ssh_port
  ssh_allowed_cidrs = var.ssh_allowed_cidrs
  api_allowed_cidrs = var.api_allowed_cidrs
  labels            = local.common_labels

  existing_control_plane_firewall_ids = try(var.existing_firewall_ids.control_plane, [])
  existing_worker_firewall_ids        = try(var.existing_firewall_ids.worker, [])
}

# ─── SSH Key ──────────────────────────────────────────────────────────────────

module "ssh_key" {
  source = "./modules/_ssh_key"

  create     = var.create
  name       = var.cluster_name
  public_key = var.ssh_public_key
  labels     = local.common_labels
}

# ─── Control Plane ────────────────────────────────────────────────────────────

module "control_plane" {
  source = "./modules/_control_plane"

  create        = var.create
  cluster_name  = var.cluster_name
  nodes         = var.control_plane_nodes
  location      = var.location
  image         = var.image
  ssh_key_ids   = compact([module.ssh_key.ssh_key_id])
  firewall_ids  = module.firewall.control_plane_firewall_ids
  network_id    = module.network.network_id
  cluster_token = try(random_password.cluster_token[0].result, "")
  rke2_version  = var.rke2_version
  rke2_config   = var.rke2_config
  ssh_port      = var.ssh_port

  delete_protection = var.delete_protection
  labels            = local.common_labels

  depends_on = [
    module.network,
    module.firewall,
  ]
}

# ─── Readiness ────────────────────────────────────────────────────────────────

module "readiness" {
  source = "./modules/_readiness"

  create              = var.create
  initial_master_ipv4 = try(module.control_plane.initial_master_ipv4, "")
  ssh_port            = var.ssh_port
  ssh_private_key     = module.ssh_key.private_key_pem

  depends_on = [module.control_plane]
}
