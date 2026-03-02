# ──────────────────────────────────────────────────────────────────────────────
# _firewall — Per-Role Firewall Primitive
#
# DECISION: Separate firewalls per node role (control_plane, worker).
# Why: Control plane and worker nodes have different security profiles.
#      Mixing rules in a single firewall violates least-privilege and makes
#      audit harder. Each role gets its own firewall with minimal rules.
# See: docs/ARCHITECTURE.md — Security Model
#
# DECISION: BYO pattern — skip creation when existing IDs are provided.
# Why: Production environments often manage firewalls centrally. This module
#      creates sensible defaults but respects pre-existing security policies.
# ──────────────────────────────────────────────────────────────────────────────

locals {
  create_control_plane_fw = var.create && length(var.existing_control_plane_firewall_ids) == 0
  create_worker_fw        = var.create && length(var.existing_worker_firewall_ids) == 0
}

# ─── Control Plane Firewall ───────────────────────────────────────────────────

resource "hcloud_firewall" "control_plane" {
  for_each = local.create_control_plane_fw ? { this = true } : {}

  name = "${var.name}-cp-fw"

  # DECISION: No SSH rule — True Zero-SSH by default.
  # Why: The module never uses SSH internally (readiness = HTTPS on 6443).
  #      Opening port 22 by default would violate least-privilege.
  #      Users who need SSH access use BYO firewall (existing_firewall_ids).
  # See: docs/ARCHITECTURE.md — Zero-SSH Design

  # Kubernetes API server
  rule {
    description = "Kubernetes API"
    direction   = "in"
    protocol    = "tcp"
    port        = "6443"
    source_ips  = var.k8s_api_allowed_cidrs
  }

  # RKE2 supervisor API (node join)
  rule {
    description = "RKE2 supervisor API"
    direction   = "in"
    protocol    = "tcp"
    port        = "9345"
    source_ips  = var.k8s_api_allowed_cidrs
  }

  # ICMP (ping) — useful for debugging, low risk
  rule {
    description = "ICMP"
    direction   = "in"
    protocol    = "icmp"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  labels = var.labels
}

# ─── Worker Firewall ─────────────────────────────────────────────────────────

resource "hcloud_firewall" "worker" {
  for_each = local.create_worker_fw ? { this = true } : {}

  name = "${var.name}-worker-fw"

  # NOTE: No SSH rule — Zero-SSH design. See control plane firewall comment.

  # HTTP ingress
  rule {
    description = "HTTP ingress"
    direction   = "in"
    protocol    = "tcp"
    port        = "80"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  # HTTPS ingress
  rule {
    description = "HTTPS ingress"
    direction   = "in"
    protocol    = "tcp"
    port        = "443"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  # ICMP
  rule {
    description = "ICMP"
    direction   = "in"
    protocol    = "icmp"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  labels = var.labels
}
