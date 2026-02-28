# Architecture

## Overview

`terraform-hcloud-ubuntu-rke2-v2` deploys an RKE2 Kubernetes cluster on Hetzner Cloud using a **composable primitive** architecture. The root module is a thin facade that orchestrates 5 independent submodules.

## Module Composition

```
Root Facade (main.tf)
│
├── random_password.cluster_token  — Shared RKE2 node registration secret
│
├── module.network (_network/)     — Private network + subnet
│   └── BYO: existing_network_id
│
├── module.firewall (_firewall/)   — Per-role firewall rules
│   └── BYO: existing_firewall_ids
│
├── module.ssh_key (_ssh_key/)     — ED25519 key pair
│   └── BYO: ssh_public_key
│
├── module.control_plane (_control_plane/)
│   ├── hcloud_server (for_each)   — Server instances
│   ├── hcloud_server_network      — Private network attachment
│   └── cloud-init template        — RKE2 installation + config
│
└── module.readiness (_readiness/)
    ├── wait_for_api               — SSH poll for API readiness
    └── fetch_kubeconfig           — SSH retrieval of kubeconfig
```

## Design Decisions

### Composable Primitives (Architecture #16)

Each submodule is independently usable. The facade wires them together but advanced users can source individual primitives:

```hcl
# Use only the network primitive
module "network" {
  source = "astract/ubuntu-rke2-v2/hcloud//modules/_network"
  name   = "my-network"
}
```

### BYO (Bring Your Own) Resources

Production teams often have pre-existing infrastructure. Each primitive supports BYO via optional input variables:

| Primitive | BYO Variable | Effect |
|-----------|-------------|--------|
| Network | `existing_network_id` | Skips network creation |
| Firewall | `existing_firewall_ids` | Skips role-specific FW creation |
| SSH Key | `ssh_public_key` | Uploads provided key, skips generation |

### for_each over count

Nodes are defined as `map(object)` and iterated with `for_each`. This ensures:
- **Stable identity**: Removing `cp-1` only destroys that node, not `cp-2`
- **Heterogeneous configs**: Each node can have different server type, location, labels
- **Clear plan output**: `module.control_plane.hcloud_server.this["cp-0"]` is self-documenting

### Provider Strategy

v2 uses 3 providers (down from 6 in v1):

| Provider | Purpose | Why kept |
|----------|---------|----------|
| hcloud | All Hetzner Cloud resources | Core dependency |
| tls | SSH key generation | Auto-generate ED25519 keys |
| random | Cluster token generation | Cryptographic random password |

Removed: `cloudinit` (templatefile replaces it), `external` (no SSH polling), `local` (no local file generation).

### Pure L3 — No Kubernetes Providers

This module creates **infrastructure only** (L3). Kubernetes-level resources (L4) — Helm charts, manifests, operators — are deployed separately via Helmfile, ArgoCD, or other tools.

This eliminates the chicken-and-egg problem of configuring kubernetes/helm providers in the same apply that creates the cluster.

### Cloud-Init over SSH

RKE2 is installed entirely via cloud-init `user_data`. No SSH-based provisioning for installation. SSH is used **only** in the readiness module for kubeconfig retrieval (documented as a COMPROMISE with a migration path to Packer images).

## Dependency Chain

```
network → firewall → ssh_key → control_plane → readiness
```

Each step depends on outputs from previous steps, wired through the facade.

## Compromise Log

| ID | Decision | Rationale | Migration Path |
|----|----------|-----------|----------------|
| C1 | SSH for kubeconfig retrieval | No API to fetch kubeconfig without prior auth | Packer pre-bake with push mechanism |
| C2 | `ignore_changes` on user_data | Cloud-init is one-shot; changes force replacement | RKE2 runtime config management |
| C3 | Join address resolution at boot | Private IPs assigned after server creation | Pre-allocated IPs (needs Hetzner API support) |

## Security Model

- **Firewall per role**: Control plane and workers have separate security profiles
- **Configurable CIDRs**: SSH and API access restricted by CIDR lists
- **SSH port customization**: Non-standard port reduces scanner noise
- **Deletion protection**: Optional but recommended for production
- **Sensitive outputs**: Private keys and tokens marked `sensitive = true`
- **No secrets in state**: Cluster token is generated, not user-supplied

## Known Gaps

- No worker node support (planned, post-MVP)
- No load balancer (planned: control-plane LB for HA, ingress LB for workloads)
- No Packer image integration (planned for immutable infrastructure)
- Kubeconfig not captured as output (remote-exec output limitation)
