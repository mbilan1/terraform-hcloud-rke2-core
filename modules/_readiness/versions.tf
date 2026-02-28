# ──────────────────────────────────────────────────────────────────────────────
# _readiness — Provider Requirements
#
# NOTE: No required_providers — this module uses only terraform_data (built-in)
#       and local-exec provisioner, neither of which require external providers.
# ──────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.8.0"
}
