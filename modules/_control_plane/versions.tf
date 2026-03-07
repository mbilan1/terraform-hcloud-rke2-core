# ──────────────────────────────────────────────────────────────────────────────
# _control_plane — Provider Requirements
#
# DECISION: Exact version pins (=) for reproducible deployments.
# Why: Aligned with root module pin strategy. Every module in the dependency
#      tree uses the same exact version to prevent constraint conflicts.
# ──────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.8.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "= 1.60.1"
    }
  }
}
