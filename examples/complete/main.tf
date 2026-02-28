# ──────────────────────────────────────────────────────────────────────────────
# Complete Example — HA Cluster with Workers & Custom Configuration
#
# This example demonstrates all module features:
# - 3-node HA control plane
# - 2 worker nodes with heterogeneous server types
# - Custom SSH port
# - Restricted API access CIDRs
# - Custom labels
# - Deletion protection
# ──────────────────────────────────────────────────────────────────────────────

module "rke2" {
  source = "../.."

  cluster_name = "production-cluster"
  location     = "hel1"
  network_zone = "eu-central"

  # HA control plane (3 nodes for etcd quorum)
  control_plane_nodes = {
    "cp-0" = {
      server_type = "cx32"
    }
    "cp-1" = {
      server_type = "cx32"
    }
    "cp-2" = {
      server_type = "cx32"
    }
  }

  # Workers with heterogeneous configs
  worker_nodes = {
    "worker-0" = {
      server_type = "cx32"
      labels = {
        "workload" = "general"
      }
    }
    "worker-1" = {
      server_type = "cx42"
      labels = {
        "workload" = "heavy"
      }
    }
  }

  # Security hardening
  ssh_port          = 2222
  ssh_allowed_cidrs = ["10.0.0.0/8"]
  api_allowed_cidrs = ["10.0.0.0/8", "192.168.0.0/16"]

  # Custom network ranges
  network_ip_range = "10.100.0.0/16"
  subnet_ip_range  = "10.100.1.0/24"

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
