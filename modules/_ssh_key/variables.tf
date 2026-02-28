# ──────────────────────────────────────────────────────────────────────────────
# _ssh_key — Variables
# ──────────────────────────────────────────────────────────────────────────────

variable "create" {
  description = "Controls whether SSH key resources are created."
  type        = bool
  default     = true
  nullable    = false
}

variable "name" {
  description = "Name prefix for the SSH key resource."
  type        = string
  nullable    = false
}

variable "public_key" {
  description = "SSH public key string. When empty, a new ED25519 key pair is generated."
  type        = string
  default     = ""
  nullable    = false
}

variable "labels" {
  description = "Labels to apply to the SSH key resource."
  type        = map(string)
  default     = {}
  nullable    = false
}
