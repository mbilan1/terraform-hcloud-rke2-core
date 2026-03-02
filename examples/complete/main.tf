# ──────────────────────────────────────────────────────────────────────────────
# Complete Example — HA Cluster with Workers & Custom Configuration
#
# This example demonstrates all module features:
# - 3-node HA control plane
# - 2 worker nodes with heterogeneous server types
# - BYO SSH key IDs (Zero-SSH — no key auto-generation)
# - Restricted API access CIDRs
# - Custom labels
# - Deletion protection
# ──────────────────────────────────────────────────────────────────────────────

module "rke2" {
  source = "../.."

  cluster_name        = "production-cluster"
  hcloud_location     = "hel1"
  hcloud_network_zone = "eu-central"

  # HA control plane (3 nodes for etcd quorum)
  # NOTE: cx32/cx42 retired by Hetzner 2026 — replaced with cx33/cx43 (same specs).
  control_plane_nodes = {
    "cp-0" = {
      server_type = "cx33"
    }
    "cp-1" = {
      server_type = "cx33"
    }
    "cp-2" = {
      server_type = "cx33"
    }
  }

  # Workers with heterogeneous configs
  worker_nodes = {
    "worker-0" = {
      server_type = "cx33"
      labels = {
        "workload" = "general"
      }
    }
    "worker-1" = {
      server_type = "cx43"
      labels = {
        "workload" = "heavy"
      }
    }
  }

  # Security hardening
  # NOTE: BYO SSH key IDs — pass existing Hetzner SSH key IDs if you need
  #       manual server access. Default is empty (True Zero-SSH).
  ssh_key_ids = []
  # NOTE: Open for testing. In production, restrict to your bastion/VPN CIDR.
  # IMPORTANT: If k8s_api_allowed_cidrs restricts access, tofu apply MUST run
  #            from within the allowed CIDR — the local-exec readiness check
  #            (curl to 6443) runs on the machine executing tofu, not the server.
  k8s_api_allowed_cidrs = ["0.0.0.0/0", "::/0"]

  # Custom network ranges
  hcloud_network_cidr = "10.100.0.0/16"
  subnet_address      = "10.100.1.0/24"

  # Lifecycle
  delete_protection = true

  # Common labels
  labels = {
    "environment" = "production"
    "team"        = "platform"
  }
}

# ─── Outputs ──────────────────────────────────────────────────────────────────

output "control_plane_ips" {
  description = "Public IPs of all control plane nodes."
  value       = module.rke2.control_plane_ipv4_addresses
}

output "cluster_ready" {
  description = "Whether the cluster API is responding."
  value       = module.rke2.cluster_ready
}
