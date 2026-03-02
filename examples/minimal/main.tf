# ──────────────────────────────────────────────────────────────────────────────
# Minimal Example — Single Control Plane Node
#
# This example deploys the absolute minimum: one control plane node
# with all defaults. Use this as a starting point for development clusters.
#
# Usage:
#   export HCLOUD_TOKEN="your-token-here"
#   tofu init
#   tofu plan
#   tofu apply
# ──────────────────────────────────────────────────────────────────────────────

module "rke2" {
  source = "../.."

  cluster_name    = "minimal-dev"
  hcloud_location = "nbg1"

  # Single control plane node (default)
  # DECISION: Single control plane node for minimal/dev use.
  # Why: Overrides the 3-node HA default to minimize cost during development.
  #      For production, remove this block and use the default (3 nodes).
  control_plane_nodes = {
    # NOTE: cx22 was retired by Hetzner in early 2026. cx23 is the direct
    #       replacement with identical specs (2 vCPU, 4 GB RAM, 40 GB SSD).
    "cp-0" = {
      server_type = "cx23"
    }
  }
}

# ─── Outputs ──────────────────────────────────────────────────────────────────

output "initial_master_ip" {
  description = "Public IP of the control plane node."
  value       = module.rke2.initial_master_ipv4
}


