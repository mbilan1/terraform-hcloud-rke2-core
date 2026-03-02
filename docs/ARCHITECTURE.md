# Architecture

## Overview

`terraform-hcloud-rke2-core` deploys an RKE2 Kubernetes cluster on Hetzner Cloud using a **composable primitive** architecture. The root module is a thin facade that orchestrates 5 independent submodules.

This module operates at **L3 (infrastructure) only** with a **zero-SSH design** — no SSH provisioners, no remote-exec. All node configuration happens via cloud-init at boot time, and cluster readiness is verified via HTTPS polling against the Kubernetes API server.

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
├── module.control_plane (_control_plane/)
│   ├── hcloud_server (for_each)   — Server instances
│   ├── hcloud_server_network      — Private network attachment
│   └── cloud-init template        — RKE2 installation + config
│
└── module.readiness (_readiness/)
    └── wait_for_api               — HTTPS poll (curl to port 6443)
```

## Design Decisions

### Zero-SSH Design Philosophy

This module uses **no SSH connections** at any stage:
- **Installation**: Cloud-init installs and configures RKE2 at boot — no remote-exec
- **Readiness**: HTTPS polling (`curl -sk https://{ip}:6443/readyz`) — no SSH
- **Kubeconfig**: Retrieved via the Rancher management module (`terraform-hcloud-rancher`), which has Kubernetes API access post-bootstrap — no SSH

SSH keys are still created/uploaded purely for **operator access** (debugging, maintenance). The module itself never uses them.

### Kubeconfig Strategy

Kubeconfig is intentionally NOT an output of this module. It is retrieved by `terraform-hcloud-rancher`, which was built specifically for this purpose. This eliminates the need for SSH-based kubeconfig retrieval and keeps this module purely L3.

### Composable Primitives (Architecture #16)

Each submodule is independently usable. The facade wires them together but advanced users can source individual primitives:

```hcl
# Use only the network primitive
module "network" {
  source = "astract/rke2-core/hcloud//modules/_network"
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

### Cloud-Init — Fully Immutable Bootstrap

RKE2 is installed entirely via cloud-init `user_data`. No SSH-based provisioning at any stage. This module follows an immutable infrastructure pattern — nodes are configured at creation and never modified in-place via SSH.

## Dependency Chain

```
network → firewall → control_plane → readiness
```

Each step depends on outputs from previous steps, wired through the facade.

## Compromise Log

| ID | Decision | Rationale | Migration Path |
|----|----------|-----------|----------------|
| C1 | `ignore_changes` on user_data | Cloud-init is one-shot; changes force replacement | RKE2 runtime config management |
| C2 | Join address resolution at boot | Private IPs assigned after server creation | Pre-allocated IPs (needs Hetzner API support) |

## Security Model

- **Firewall per role**: Control plane and workers have separate security profiles
- **Configurable CIDRs**: SSH and API access restricted by CIDR lists
- **SSH port customization**: Non-standard port reduces scanner noise
- **Deletion protection**: Optional but recommended for production
- **Sensitive outputs**: Private keys and tokens marked `sensitive = true`
- **No secrets in state**: Cluster token is generated, not user-supplied

## Design Boundaries (By Design, Not Gaps)

The following items are intentionally **out of scope** for this module:

| Item | Rationale | Where it lives |
|------|-----------|---------------|
| Worker nodes | Only control-plane nodes installed by default. Workers added as needed. | Future `_worker` primitive or consumer module |
| Load balancer | Control-plane LB and ingress LB are separate concerns | Separate module (`terraform-hcloud-lb` or similar) |
| Packer images | Image baking is a separate workflow with different lifecycle | Separate Packer configuration |
| Kubeconfig retrieval | Zero-SSH design — kubeconfig fetched by Rancher module | `terraform-hcloud-rancher` |
