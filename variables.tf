# ──────────────────────────────────────────────────────────────────────────────
# VARIABLES — flat user-facing API
#
# DECISION: Flat variables instead of nested objects for the root API.
# Why: Flat variables are easier to override per-environment, produce clearer
#      plan diffs, and avoid the "object merge" footgun where omitting one
#      field resets it to default. Individual BYO inputs (existing_network_id,
#      existing_firewall_ids) replace v1's implicit create-or-skip patterns.
# See: docs/ARCHITECTURE.md — Variable Design
#
# DECISION: Block ordering follows terraform-skill convention:
#   description → type → default → sensitive → nullable → validation
# ──────────────────────────────────────────────────────────────────────────────

# ─── Master Toggle ────────────────────────────────────────────────────────────

variable "create" {
  description = "Controls whether any resources are created. Set to false to disable the entire module."
  type        = bool
  default     = true
  nullable    = false
}

# ─── Cluster Identity ─────────────────────────────────────────────────────────

variable "cluster_name" {
  description = "Name prefix for all created resources. Must be lowercase alphanumeric with hyphens, 3-63 characters."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,61}[a-z0-9]$", var.cluster_name))
    error_message = "Must be 3-63 characters, start with a letter, end with alphanumeric, contain only lowercase letters, digits, and hyphens."
  }
}

# ─── Location & Network Zone ─────────────────────────────────────────────────

variable "hcloud_location" {
  description = "Hetzner Cloud datacenter location for servers and resources."
  type        = string
  default     = "nbg1"
  nullable    = false

  validation {
    # NOTE: sin (Singapore, ap-southeast) added 2026-03-01 — verified live via
    #       Hetzner API: https://api.hetzner.cloud/v1/locations
    condition     = contains(["nbg1", "fsn1", "hel1", "ash", "hil", "sin"], var.hcloud_location)
    error_message = "Must be a valid Hetzner Cloud location: nbg1, fsn1, hel1, ash, hil, sin."
  }
}

variable "hcloud_network_zone" {
  description = "Hetzner Cloud network zone. Must match the hcloud_location's region."
  type        = string
  default     = "eu-central"
  nullable    = false

  validation {
    condition     = contains(["eu-central", "us-east", "us-west", "ap-southeast"], var.hcloud_network_zone)
    error_message = "Must be a valid Hetzner Cloud network zone."
  }
}

# ─── Network Configuration ────────────────────────────────────────────────────

variable "hcloud_network_cidr" {
  description = "IP range for the private network in CIDR notation."
  type        = string
  default     = "10.0.0.0/16"
  nullable    = false
}

variable "subnet_address" {
  description = "IP range for the subnet in CIDR notation. Must be within hcloud_network_cidr."
  type        = string
  default     = "10.0.1.0/24"
  nullable    = false
}

variable "existing_network_id" {
  description = "ID of an existing Hetzner Cloud network. When set, network creation is skipped (BYO network)."
  type        = number
  default     = null
}

# ─── Firewall Configuration ──────────────────────────────────────────────────

variable "k8s_api_allowed_cidrs" {
  description = "List of CIDR blocks allowed to access the Kubernetes API (port 6443)."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
  nullable    = false
}

variable "existing_firewall_ids" {
  description = "Map of existing firewall IDs per role. When set for a role, firewall creation is skipped for that role (BYO firewall)."
  type = object({
    control_plane = optional(list(number), [])
    worker        = optional(list(number), [])
  })
  default = null
}

# ─── SSH Key (BYO) ───────────────────────────────────────────────────────────

# DECISION: True Zero-SSH — no key auto-generation.
# Why: OpenTofu never uses SSH internally (readiness = HTTPS curl on 6443).
#      Auto-generating keys contradicts the Zero-SSH philosophy and creates
#      unnecessary credentials. Users who need SSH access bring their own
#      pre-existing Hetzner SSH key IDs.
# See: docs/ARCHITECTURE.md — Zero-SSH Design
variable "ssh_key_ids" {
  description = "List of existing Hetzner SSH key IDs to inject into nodes. Default empty = True Zero-SSH. BYO: pass your pre-created key IDs."
  type        = list(number)
  default     = []
  nullable    = false
}

# ─── Node Definitions ────────────────────────────────────────────────────────

variable "control_plane_nodes" {
  description = "Map of control plane node definitions. Keys are node identifiers, values configure each server."
  type = map(object({
    # NOTE: cx22 retired by Hetzner 2026 — replaced with cx23 (same specs).
    server_type = optional(string, "cx23")
    location    = optional(string)
    labels      = optional(map(string), {})
    backups     = optional(bool, false)
  }))
  # DECISION: Default is 3-node HA cluster, not single-node.
  # Why: Single-node clusters are dev-only; production operators should never
  #      accidentally deploy a non-HA cluster. Explicit override required for
  #      single-node (e.g. examples/minimal).
  default = {
    "cp-0" = {}
    "cp-1" = {}
    "cp-2" = {}
  }
  nullable = false

  validation {
    condition     = length(var.control_plane_nodes) > 0
    error_message = "At least one control plane node is required."
  }

  validation {
    condition     = length(var.control_plane_nodes) != 2
    error_message = "Two control plane nodes break etcd quorum. Use 1 (dev) or 3+ (HA)."
  }
}

variable "worker_nodes" {
  description = "Map of worker node definitions. Keys are node identifiers. Empty map means no workers."
  type = map(object({
    # NOTE: cx22 retired by Hetzner 2026 — replaced with cx23 (same specs).
    server_type = optional(string, "cx23")
    location    = optional(string)
    labels      = optional(map(string), {})
    backups     = optional(bool, false)
  }))
  default  = {}
  nullable = false
}

# ─── RKE2 Configuration ──────────────────────────────────────────────────────

variable "rke2_version" {
  description = "RKE2 version to install. Empty string uses the upstream stable channel (less reproducible)."
  type        = string
  default     = "v1.32.2+rke2r1"
  nullable    = false
}

variable "rke2_config" {
  description = "Additional RKE2 config.yaml content appended to every node's configuration."
  type        = string
  default     = ""
  nullable    = false
}

# ─── OS Image ─────────────────────────────────────────────────────────────────

variable "hcloud_image" {
  description = "OS image for all nodes. Must be an Ubuntu 24.04 image name or ID."
  type        = string
  default     = "ubuntu-24.04"
  nullable    = false
}

# ─── Deletion Protection ─────────────────────────────────────────────────────

variable "delete_protection" {
  description = "Enable deletion protection on servers and load balancers."
  type        = bool
  default     = false
  nullable    = false
}

# ─── Labels ───────────────────────────────────────────────────────────────────

variable "labels" {
  description = "Common labels applied to all created resources. Merged with node-specific labels."
  type        = map(string)
  default     = {}
  nullable    = false
}
