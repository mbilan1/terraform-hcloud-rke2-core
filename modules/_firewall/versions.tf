# ──────────────────────────────────────────────────────────────────────────────
# _firewall — Provider Requirements
#
# NOTE: Child modules use floor constraints (>=) per terraform-skill convention.
#       The root module pins the upper bound with pessimistic (~>) constraints.
# ──────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.8.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.49"
    }
  }
}
