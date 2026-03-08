# ──────────────────────────────────────────────────────────────────────────────
# _control_plane — Variables
# ──────────────────────────────────────────────────────────────────────────────

variable "create" {
  description = "Controls whether server resources are created."
  type        = bool
  default     = true
  nullable    = false
}

variable "cluster_name" {
  description = "Cluster name used as prefix for server names."
  type        = string
  nullable    = false
}

variable "nodes" {
  description = "Map of control plane node definitions."
  type = map(object({
    # NOTE: cx22 was retired by Hetzner in early 2026 and is no longer available
    #       for new server creation. cx23 is the direct replacement (same specs:
    #       2 vCPU, 4 GB RAM, 40 GB SSD). Verified via live API 2026-03-01.
    # See: https://docs.hetzner.cloud/ — Server Types
    server_type = optional(string, "cx23")
    location    = optional(string)
    labels      = optional(map(string), {})
    backups     = optional(bool, false)
  }))
  nullable = false
}

variable "hcloud_location" {
  description = "Default Hetzner Cloud location for nodes without explicit location."
  type        = string
  nullable    = false
}

variable "hcloud_image" {
  description = "OS image name or ID for the servers."
  type        = string
  default     = "ubuntu-24.04"
  nullable    = false
}

variable "ssh_key_ids" {
  description = "List of Hetzner SSH key IDs to attach to servers."
  type        = list(number)
  default     = []
  nullable    = false
}

variable "firewall_ids" {
  description = "List of firewall IDs to attach to servers."
  type        = list(number)
  default     = []
  nullable    = false
}

variable "network_id" {
  description = "Hetzner network ID for private networking. Null when create=false and no BYO network."
  type        = number
  default     = null
  # NOTE: nullable = true (implicit) because when create=false, the network
  # module outputs null and no server_network resources are created anyway.
}

variable "cluster_token" {
  description = "Shared secret token for RKE2 node registration."
  type        = string
  sensitive   = true
  nullable    = false
}

variable "rke2_version" {
  description = "RKE2 version to install."
  type        = string
  default     = "v1.34.4+rke2r1"
  nullable    = false
}

variable "rke2_config" {
  description = "Additional RKE2 config.yaml content."
  type        = string
  default     = ""
  nullable    = false
}

variable "extra_server_manifests" {
  description = "Map of filename => YAML content to place in /var/lib/rancher/rke2/server/manifests/. RKE2 HelmController installs HelmChart CRDs found there automatically."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "delete_protection" {
  description = "Enable deletion and rebuild protection on servers."
  type        = bool
  default     = false
  nullable    = false
}

variable "labels" {
  description = "Common labels applied to all servers."
  type        = map(string)
  default     = {}
  nullable    = false
}
