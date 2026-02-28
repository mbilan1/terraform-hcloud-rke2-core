# ──────────────────────────────────────────────────────────────────────────────
# _readiness — Variables
# ──────────────────────────────────────────────────────────────────────────────

variable "create" {
  description = "Controls whether readiness checks are executed."
  type        = bool
  default     = true
  nullable    = false
}

variable "initial_master_ipv4" {
  description = "Public IPv4 address of the initial master node."
  type        = string
  nullable    = false
}

variable "ssh_port" {
  description = "SSH port for connecting to the initial master."
  type        = number
  default     = 22
  nullable    = false
}

variable "ssh_private_key" {
  description = "SSH private key for connecting to the initial master."
  type        = string
  sensitive   = true
  nullable    = false
}
