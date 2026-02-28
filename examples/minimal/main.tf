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

  cluster_name = "minimal-dev"
  location     = "nbg1"

  # Single control plane node (default)
  control_plane_nodes = {
    "cp-0" = {
      server_type = "cx22"
    }
  }
}

# ─── Outputs ──────────────────────────────────────────────────────────────────

output "initial_master_ip" {
  description = "Public IP of the control plane node."
  value       = module.rke2.initial_master_ipv4
}

output "ssh_private_key" {
  description = "Auto-generated SSH private key (save to file for access)."
  value       = module.rke2.ssh_private_key
  sensitive   = true
}
