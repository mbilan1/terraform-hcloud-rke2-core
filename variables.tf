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

  validation {
    condition     = can(cidrhost(var.hcloud_network_cidr, 0))
    error_message = "Must be a valid CIDR notation (e.g. 10.0.0.0/16)."
  }
}

variable "subnet_address" {
  description = "IP range for the subnet in CIDR notation. Must be within hcloud_network_cidr."
  type        = string
  default     = "10.0.1.0/24"
  nullable    = false

  validation {
    condition     = can(cidrhost(var.subnet_address, 0))
    error_message = "Must be a valid CIDR notation (e.g. 10.0.1.0/24)."
  }
}

# NOTE: Intentionally nullable — null = "create new network" (BYO pattern).
variable "existing_network_id" {
  description = "ID of an existing Hetzner Cloud network. When set, network creation is skipped (BYO network)."
  type        = number
  default     = null
}

# ─── Firewall (BYO) ──────────────────────────────────────────────────────────

# DECISION: BYO Firewall — no firewall creation in the module.
# Why: Hetzner firewalls are account-level singletons, not per-cluster.
#      Embedding firewall rules couples the module to a specific security
#      policy. Consumers create firewalls externally and pass IDs.
# See: ADR-006 in rke2-hetzner-architecture
variable "firewall_ids" {
  description = "List of Hetzner firewall IDs to attach to all nodes. BYO: create firewalls externally and pass their IDs."
  type        = list(number)
  default     = []
  nullable    = false
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

# ─── RKE2 Configuration ──────────────────────────────────────────────────────

variable "rke2_version" {
  description = "RKE2 version to install. Empty string uses the upstream stable channel (less reproducible)."
  type        = string
  default     = "v1.34.4+rke2r1"
  nullable    = false

  validation {
    condition     = var.rke2_version == "" || can(regex("^v\\d+\\.\\d+\\.\\d+\\+rke2r\\d+$", var.rke2_version))
    error_message = "Must be empty or a valid RKE2 version (e.g. v1.34.4+rke2r1)."
  }
}

# DECISION: Single CIS feature flag for both Packer and Profile flows.
# Why: RKE2 CIS profile (profile: cis) requires OS-level prerequisites
#      (etcd user, kernel params) BEFORE rke2-server starts. This flag
#      handles both the prerequisites and the config entry atomically.
#      Prerequisites are idempotent — safe on both stock images (cloud-init
#      creates them) and Packer golden images (already baked in by rke2-base).
# See: https://docs.rke2.io/security/hardening_guide
variable "enable_cis" {
  description = "Enable RKE2 CIS hardening. Creates etcd user, sets required kernel params, and adds 'profile: cis' to config.yaml. Safe on both stock images and Packer golden images (prerequisites are idempotent)."
  type        = bool
  default     = false
  nullable    = false
}

variable "rke2_config" {
  description = "Additional RKE2 config.yaml content appended to every node's configuration."
  type        = string
  default     = ""
  nullable    = false
}

variable "extra_server_manifests" {
  description = "Map of filename => YAML content placed in /var/lib/rancher/rke2/server/manifests/. RKE2 HelmController auto-installs HelmChart CRDs found there. Allows consumers to deploy Helm charts (e.g. cert-manager, Rancher) without direct K8s API access from Terraform."
  type        = map(string)
  default     = {}
  nullable    = false
}

# ─── OS Image ─────────────────────────────────────────────────────────────────

variable "hcloud_image" {
  description = "OS image for all nodes. Must be an Ubuntu 24.04 image name or ID."
  type        = string
  default     = "ubuntu-24.04"
  nullable    = false

  validation {
    condition     = length(var.hcloud_image) > 0
    error_message = "Image name must not be empty."
  }
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
