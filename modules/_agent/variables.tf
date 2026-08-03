# ──────────────────────────────────────────────────────────────────────────────
# _agent — Input Variables
#
# Mirrors _control_plane where the concern is identical (identity, image,
# network, token). Omits everything that only a server node owns: etcd
# bootstrap, extra_server_manifests, PSA admission config.
# ──────────────────────────────────────────────────────────────────────────────

variable "create" {
  description = "Whether to create agent servers. When false, the module is a no-op."
  type        = bool
  default     = true
  nullable    = false
}

variable "cluster_name" {
  description = "Cluster name — used as the server name prefix."
  type        = string
  nullable    = false
}

variable "nodes" {
  description = <<-EOT
    Map of agent (worker) node definitions. Map keys are stable identifiers —
    removing a key destroys only that server, unlike count-based indexing.

    node_labels / node_taints are applied by RKE2 itself at registration time
    (kubelet --node-labels / --node-taint), so they survive node restarts and
    do not require a separate kubectl step.
  EOT
  type = map(object({
    server_type = optional(string, "cx23")
    location    = optional(string)
    labels      = optional(map(string), {})
    backups     = optional(bool, false)
    node_labels = optional(list(string), [])
    node_taints = optional(list(string), [])
  }))
  default  = {}
  nullable = false
}

variable "hcloud_location" {
  description = "Default Hetzner location for agent nodes that do not set their own."
  type        = string
  nullable    = false
}

variable "hcloud_image" {
  description = "Hetzner image (or snapshot id) used for agent nodes."
  type        = string
  nullable    = false
}

variable "ssh_key_ids" {
  description = <<-EOT
    BYO Hetzner SSH key IDs. Empty by default — True Zero-SSH (ADR-002).
  EOT
  type        = list(string)
  default     = []
  nullable    = false
}

variable "firewall_ids" {
  description = "Hetzner firewall IDs attached to agent servers (BYO — ADR-006)."
  type        = list(number)
  default     = []
  nullable    = false
}

variable "network_id" {
  description = "Private network ID the agents attach to."
  type        = string
  nullable    = false
}

variable "cluster_token" {
  description = "Shared RKE2 cluster token — agents authenticate to the supervisor with it."
  type        = string
  sensitive   = true
  nullable    = false
}

variable "join_address" {
  description = <<-EOT
    Private IPv4 of a control-plane node to join through (supervisor port 9345).

    DECISION: Private IP, not a load balancer.
    Why: Consistent with the control-plane join path — supervisor traffic stays
         on the private network, where no Hetzner firewall filtering applies.
  EOT
  type        = string
  nullable    = false
}

variable "rke2_version" {
  description = "RKE2 version to install. Empty string installs the latest stable."
  type        = string
  default     = ""
  nullable    = false
}

variable "rke2_config" {
  description = "Extra raw YAML appended to the agent's /etc/rancher/rke2/config.yaml."
  type        = string
  default     = ""
  nullable    = false
}

variable "enable_cis" {
  description = "Apply the CIS hardening profile and its host prerequisites."
  type        = bool
  default     = false
  nullable    = false
}

variable "delete_protection" {
  description = "Enable Hetzner delete and rebuild protection on agent servers."
  type        = bool
  default     = false
  nullable    = false
}

variable "labels" {
  description = "Hetzner labels applied to every agent server."
  type        = map(string)
  default     = {}
  nullable    = false
}
