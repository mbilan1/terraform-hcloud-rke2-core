# Minimal Example — Variables

variable "hcloud_token" {
  description = "Hetzner Cloud API token. Prefer setting via HCLOUD_TOKEN env var."
  type        = string
  sensitive   = true
  default     = null
}
