# ──────────────────────────────────────────────────────────────────────────────
# Complete Example — HA Cluster with Custom Configuration
#
# This example demonstrates all module features:
# - 3-node HA control plane with pinned RKE2 version
# - BYO SSH key IDs (Zero-SSH — no key auto-generation)
# - BYO firewall IDs
# - Extra server manifests (HelmChart CRDs deployed via cloud-init)
# - Custom labels and deletion protection
# ──────────────────────────────────────────────────────────────────────────────

module "rke2" {
  source = "../.."

  cluster_name        = "production-cluster"
  hcloud_location     = "hel1"
  hcloud_network_zone = "eu-central"

  # Pin RKE2 version for reproducible deployments
  rke2_version = "v1.34.4+rke2r1"

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

  # Additional RKE2 config.yaml content
  rke2_config = <<-EOT
    etcd-snapshot-schedule-cron: "0 */6 * * *"
    etcd-snapshot-retention: 5
  EOT

  # Security hardening
  # NOTE: BYO SSH key IDs — pass existing Hetzner SSH key IDs if you need
  #       manual server access. Default is empty (True Zero-SSH).
  ssh_key_ids = []

  # BYO firewall — create firewalls externally and pass IDs (ADR-006)
  firewall_ids = [hcloud_firewall.rke2.id]

  # Custom network ranges
  hcloud_network_cidr = "10.100.0.0/16"
  subnet_address      = "10.100.1.0/24"

  # Extra manifests deployed via cloud-init into /var/lib/rancher/rke2/server/manifests/
  # RKE2 HelmController auto-installs HelmChart CRDs found there.
  extra_server_manifests = {}

  # Lifecycle
  delete_protection = true

  # Common labels
  labels = {
    "environment" = "production"
    "team"        = "platform"
  }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  BYO Firewall (ADR-006)                                                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# DECISION: Firewall created in the example, not in the module.
# Why: ADR-006 — firewalls are BYO. Hetzner firewalls are account-level
#      singletons with per-server attachment. The module accepts firewall_ids;
#      consumers create and manage firewall rules externally.
resource "hcloud_firewall" "rke2" {
  name = "production-cluster-rke2"

  labels = {
    "cluster-name" = "production-cluster"
    "managed-by"   = "opentofu"
  }

  # ICMP — diagnostics
  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # K8s API — restrict to operator networks
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "6443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # RKE2 supervisor — node join (restrict in production)
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "9345"
    source_ips = ["0.0.0.0/0", "::/0"]
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
