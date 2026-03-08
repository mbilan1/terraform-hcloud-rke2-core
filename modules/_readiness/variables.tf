# ──────────────────────────────────────────────────────────────────────────────
# _readiness — Variables
#
# DECISION: Only two variables — create toggle and target IP.
# Why: Zero-SSH design means no SSH port or private key needed. The readiness
#      check uses HTTPS polling from the local machine, not SSH to the target.
# ──────────────────────────────────────────────────────────────────────────────

variable "create" {
  description = "Controls whether readiness checks are executed."
  type        = bool
  default     = true
  nullable    = false
}

variable "initial_master_ipv4" {
  description = "Public IPv4 address of the initial master node. Null when create=false."
  type        = string
  default     = ""
  nullable    = false
}
