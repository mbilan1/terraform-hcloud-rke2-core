# ──────────────────────────────────────────────────────────────────────────────
# VERSION REGISTRY — single reference for every versioned component
#
# DECISION: Minimal provider set — 2 providers for pure L3 infrastructure.
# Why: v1 used 6 providers (hcloud, cloudinit, external, tls, random, local).
#      v2 eliminates cloudinit (uses raw templatefile), external (no SSH
#      polling), tls (no key auto-generation — True Zero-SSH), and local
#      (no local file generation). Fewer providers means faster init,
#      smaller lock files, and fewer upgrade constraints.
# See: docs/ARCHITECTURE.md — Provider Strategy
#
# ┌──────────────────────────────┬──────────────────────┬──────────────────────┐
# │ Component                    │ Version              │ Defined in           │
# ├──────────────────────────────┼──────────────────────┼──────────────────────┤
# │ OpenTofu (runtime)           │ >= 1.8.0             │ versions.tf          │
# │ RKE2 / Kubernetes            │ v1.32.2+rke2r1       │ var.rke2_version     │
# │ OS image                     │ ubuntu-24.04         │ var.hcloud_image     │
# ├──────────────────────────────┼──────────────────────┼──────────────────────┤
# │ Provider: hcloud             │ ~> 1.49              │ versions.tf          │
# │ Provider: random             │ ~> 3.6               │ versions.tf          │
# └──────────────────────────────┴──────────────────────┴──────────────────────┘
#
# NOTE: Provider version constraints use pessimistic (~>) in the root module.
#       Child modules use floor constraints (>=) per terraform-skill convention.
# ──────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.8.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.49"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
