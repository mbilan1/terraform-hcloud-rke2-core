# ──────────────────────────────────────────────────────────────────────────────
# _network — Variables
# ──────────────────────────────────────────────────────────────────────────────

variable "create" {
  description = "Controls whether network resources are created."
  type        = bool
  default     = true
  nullable    = false
}

variable "name" {
  description = "Name prefix for the network resource."
  type        = string
  nullable    = false
}

variable "ip_range" {
  description = "IP range for the network in CIDR notation."
  type        = string
  default     = "10.0.0.0/16"
  nullable    = false
}

variable "subnet_ip_range" {
  description = "IP range for the subnet in CIDR notation."
  type        = string
  default     = "10.0.1.0/24"
  nullable    = false
}

variable "network_zone" {
  description = "Hetzner Cloud network zone for the subnet."
  type        = string
  default     = "eu-central"
  nullable    = false
}

variable "existing_network_id" {
  description = "ID of an existing network. When set, no network is created."
  type        = number
  default     = null
}

variable "delete_protection" {
  description = "Enable deletion protection on the network."
  type        = bool
  default     = false
  nullable    = false
}

variable "labels" {
  description = "Labels to apply to the network."
  type        = map(string)
  default     = {}
  nullable    = false
}
