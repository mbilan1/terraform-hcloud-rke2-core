# ──────────────────────────────────────────────────────────────────────────────
# _firewall — Variables
# ──────────────────────────────────────────────────────────────────────────────

variable "create" {
  description = "Controls whether firewall resources are created."
  type        = bool
  default     = true
  nullable    = false
}

variable "name" {
  description = "Name prefix for firewall resources."
  type        = string
  nullable    = false
}

variable "ssh_port" {
  description = "SSH port number for the SSH access rule."
  type        = number
  default     = 22
  nullable    = false
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed SSH access. Empty list disables the SSH rule."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
  nullable    = false
}

variable "k8s_api_allowed_cidrs" {
  description = "CIDR blocks allowed to access Kubernetes API (6443) and RKE2 supervisor (9345)."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
  nullable    = false
}

variable "existing_control_plane_firewall_ids" {
  description = "Existing firewall IDs for the control plane role. When non-empty, control plane firewall creation is skipped."
  type        = list(number)
  default     = []
  nullable    = false
}

variable "existing_worker_firewall_ids" {
  description = "Existing firewall IDs for the worker role. When non-empty, worker firewall creation is skipped."
  type        = list(number)
  default     = []
  nullable    = false
}

variable "labels" {
  description = "Labels to apply to firewall resources."
  type        = map(string)
  default     = {}
  nullable    = false
}
