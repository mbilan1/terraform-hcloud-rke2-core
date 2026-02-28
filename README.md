# terraform-hcloud-rke2-core

OpenTofu module to deploy a production-oriented **RKE2 Kubernetes cluster on Hetzner Cloud**.

## Features

- **Composable primitives**: 5 independent submodules (network, firewall, SSH key, control plane, readiness)
- **BYO resources**: Bring your own network, firewall, or SSH key
- **HA control plane**: 1, 3, or 5 node configurations with etcd quorum validation
- **`for_each` node identity**: Stable node addressing via map keys (no count drift)
- **Flat variable API**: Simple overrides, clear plan diffs
- **Preflight guardrails**: Cross-variable checks warn about risky configurations
- **Zero-credential tests**: `tofu test` with mock providers (~3s, $0)

## Quick Start

```hcl
module "rke2" {
  source  = "astract/rke2-core/hcloud"

  cluster_name = "my-cluster"
  location     = "nbg1"

  control_plane_nodes = {
    "cp-0" = { server_type = "cx22" }
  }
}
```

## Architecture

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for full design rationale.

```
Root Facade
├── modules/_network/        # VPC + subnet (BYO support)
├── modules/_firewall/       # Per-role firewalls (BYO support)
├── modules/_ssh_key/        # ED25519 key pair (BYO support)
├── modules/_control_plane/  # Servers with cloud-init RKE2 bootstrap
└── modules/_readiness/      # API health check + kubeconfig retrieval
```

## Requirements

| Name | Version |
|------|---------|
| OpenTofu | >= 1.8.0 |
| hcloud provider | ~> 1.49 |
| tls provider | ~> 4.0 |
| random provider | ~> 3.6 |

## Examples

- [Minimal](examples/minimal/) — Single node dev cluster
- [Complete](examples/complete/) — HA cluster with workers, custom networking, security hardening

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
