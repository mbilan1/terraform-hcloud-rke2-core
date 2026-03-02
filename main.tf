# ──────────────────────────────────────────────────────────────────────────────
# FACADE — Root Module Orchestration
#
# DECISION: Root module is a thin facade calling 4 independent primitives.
# Why: Each primitive (_network, _firewall, _control_plane,
#      _readiness) is independently usable and testable. The facade wires
#      them together with sensible defaults, handling the dependency chain:
#      network → firewall → control_plane → readiness.
#
# DECISION: True Zero-SSH — no SSH key management in the module.
# Why: OpenTofu never uses SSH internally (readiness = HTTPS curl on 6443).
#      Generating keys would create unnecessary credentials and contradict
#      the Zero-SSH philosophy. Users pass ssh_key_ids = [] (default) or
#      inject their own pre-existing Hetzner key IDs.
# See: docs/ARCHITECTURE.md — Zero-SSH Design
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
#
# NOTE: random_password results are auto-sensitive in OpenTofu, but the
#       resource doesn't expose an explicit `sensitive` argument. The output
#       is correctly marked sensitive in outputs.tf.
resource "random_password" "cluster_token" {
  for_each = var.create ? { this = true } : {}

  length  = 64
  special = false
}

# ─── Network ──────────────────────────────────────────────────────────────────

module "network" {
  source = "./modules/_network"

  create              = var.create
  name                = var.cluster_name
  ip_range            = var.hcloud_network_cidr
  subnet_address      = var.subnet_address
  hcloud_network_zone = var.hcloud_network_zone
  existing_network_id = var.existing_network_id
  delete_protection   = var.delete_protection
  labels              = local.common_labels
}

# ─── Firewall ─────────────────────────────────────────────────────────────────

module "firewall" {
  source = "./modules/_firewall"

  create                = var.create
  name                  = var.cluster_name
  k8s_api_allowed_cidrs = var.k8s_api_allowed_cidrs
  labels                = local.common_labels

  existing_control_plane_firewall_ids = try(var.existing_firewall_ids.control_plane, [])
  existing_worker_firewall_ids        = try(var.existing_firewall_ids.worker, [])
}

# ─── Control Plane ────────────────────────────────────────────────────────────

module "control_plane" {
  source = "./modules/_control_plane"

  create          = var.create
  cluster_name    = var.cluster_name
  nodes           = var.control_plane_nodes
  hcloud_location = var.hcloud_location
  hcloud_image    = var.hcloud_image
  # DECISION: BYO SSH keys passed directly — no auto-generation.
  # Why: True Zero-SSH. User provides [] (default) or existing Hetzner key IDs.
  ssh_key_ids   = var.ssh_key_ids
  firewall_ids  = module.firewall.control_plane_firewall_ids
  network_id    = module.network.network_id
  cluster_token = try(random_password.cluster_token["this"].result, "")
  rke2_version  = var.rke2_version
  rke2_config   = var.rke2_config

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

  # DECISION: Only pass IP — no SSH credentials needed.
  # Why: Readiness uses HTTPS polling (curl to port 6443), not SSH.
  #      Zero-SSH design: no private key dependency between primitives.
  create              = var.create
  initial_master_ipv4 = try(module.control_plane.initial_master_ipv4, "")

  depends_on = [module.control_plane]
}
