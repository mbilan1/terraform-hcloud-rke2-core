# terraform-hcloud-rke2-core

[![Lint: fmt](https://github.com/mbilan1/terraform-hcloud-rke2-core/actions/workflows/lint-fmt.yml/badge.svg)](https://github.com/mbilan1/terraform-hcloud-rke2-core/actions/workflows/lint-fmt.yml)
[![Lint: validate](https://github.com/mbilan1/terraform-hcloud-rke2-core/actions/workflows/lint-validate.yml/badge.svg)](https://github.com/mbilan1/terraform-hcloud-rke2-core/actions/workflows/lint-validate.yml)
[![Lint: tflint](https://github.com/mbilan1/terraform-hcloud-rke2-core/actions/workflows/lint-tflint.yml/badge.svg)](https://github.com/mbilan1/terraform-hcloud-rke2-core/actions/workflows/lint-tflint.yml)

[![SAST: Checkov](https://github.com/mbilan1/terraform-hcloud-rke2-core/actions/workflows/sast-checkov.yml/badge.svg)](https://github.com/mbilan1/terraform-hcloud-rke2-core/actions/workflows/sast-checkov.yml)
[![SAST: KICS](https://github.com/mbilan1/terraform-hcloud-rke2-core/actions/workflows/sast-kics.yml/badge.svg)](https://github.com/mbilan1/terraform-hcloud-rke2-core/actions/workflows/sast-kics.yml)
[![SAST: tfsec](https://github.com/mbilan1/terraform-hcloud-rke2-core/actions/workflows/sast-tfsec.yml/badge.svg)](https://github.com/mbilan1/terraform-hcloud-rke2-core/actions/workflows/sast-tfsec.yml)

[![Test: variables](https://github.com/mbilan1/terraform-hcloud-rke2-core/actions/workflows/unit-variables.yml/badge.svg)](https://github.com/mbilan1/terraform-hcloud-rke2-core/actions/workflows/unit-variables.yml)
[![Test: guardrails](https://github.com/mbilan1/terraform-hcloud-rke2-core/actions/workflows/unit-guardrails.yml/badge.svg)](https://github.com/mbilan1/terraform-hcloud-rke2-core/actions/workflows/unit-guardrails.yml)

[![Integration: plan](https://github.com/mbilan1/terraform-hcloud-rke2-core/actions/workflows/integration-plan.yml/badge.svg)](https://github.com/mbilan1/terraform-hcloud-rke2-core/actions/workflows/integration-plan.yml)
[![E2E: apply](https://github.com/mbilan1/terraform-hcloud-rke2-core/actions/workflows/e2e-apply.yml/badge.svg)](https://github.com/mbilan1/terraform-hcloud-rke2-core/actions/workflows/e2e-apply.yml)

<!-- Version badges — source: versions.tf (required_version, required_providers), variables.tf (rke2_version) -->
![OpenTofu](https://img.shields.io/badge/OpenTofu-%3E%3D1.8.0-844FBA?logo=opentofu&logoColor=white)
![hcloud](https://img.shields.io/badge/hcloud-1.60.1-E10000?logo=hetzner&logoColor=white)
![random](https://img.shields.io/badge/random-3.8.1-7B42BC?logo=terraform&logoColor=white)
![RKE2](https://img.shields.io/badge/RKE2-v1.34.4%2Brke2r1-0075A8?logo=kubernetes&logoColor=white)

> **⚠️ Experimental (Beta)** — This is an **unofficial** community implementation, under active development and **not production-ready**.
> APIs, variables, and behavior may change without notice. Use at your own risk.
> No stability guarantees are provided until v1.0.0.

OpenTofu module to deploy an **RKE2 Kubernetes cluster on Hetzner Cloud**.

## Ecosystem

This module is part of the **RKE2-on-Hetzner** ecosystem — a set of interconnected projects that together provide a complete Kubernetes management platform on Hetzner Cloud.

| Repository | Role in Ecosystem |
|---|---|
| **`terraform-hcloud-rke2-core`** (this repo) | **L3 infrastructure primitive — servers, network, readiness** |
| [`terraform-hcloud-rancher`](https://github.com/mbilan1/terraform-hcloud-rancher) | Management cluster — Rancher + Node Driver on RKE2 |
| [`rancher-hetzner-cluster-templates`](https://github.com/mbilan1/rancher-hetzner-cluster-templates) | Downstream cluster provisioning via Rancher UI |
| [`packer-hcloud-rke2`](https://github.com/mbilan1/packer-hcloud-rke2) | Packer node image — CIS-hardened snapshots |

```
rke2-core (L3 infra) → rancher (L3+L4 management) → cluster-templates (downstream via UI)
                                                    ↑
                                        packer (node images)
```

## Features

- **Composable primitives**: 3 independent submodules (network, control plane, readiness)
- **BYO resources**: Bring your own network or firewall
- **BYO Firewall**: Pass pre-existing Hetzner firewall IDs (no embedded rules)
- **HA control plane**: 1, 3, or 5 node configurations with etcd quorum validation
- **`for_each` node identity**: Stable node addressing via map keys (no count drift)
- **Flat variable API**: Simple overrides, clear plan diffs
- **Preflight guardrails**: Cross-variable checks warn about risky configurations
- **CIS hardening**: Optional RKE2 CIS profile via `enable_cis` (idempotent with Packer images)
- **Zero-credential tests**: `tofu test` with mock providers (~3s, $0)

## Quick Start

```hcl
module "rke2" {
  source = "git::https://github.com/mbilan1/terraform-hcloud-rke2-core.git"

  cluster_name = "my-cluster"
  hcloud_location = "nbg1"

  control_plane_nodes = {
    "cp-0" = { server_type = "cx23" }
  }
}
```

## Architecture

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for full design rationale.

```
Root Facade
├── modules/_network/        # VPC + subnet (BYO support)
├── modules/_control_plane/  # Servers with cloud-init RKE2 bootstrap
└── modules/_readiness/      # API health check
```

## Requirements

| Name | Version |
|------|---------|
| OpenTofu | >= 1.8.0 |
| hcloud provider | ~> 1.49 |
| random provider | ~> 3.6 |

## Examples

- [Minimal](examples/minimal/) — Single node dev cluster
- [Complete](examples/complete/) — HA cluster with workers, custom networking, security hardening

<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0 |
| <a name="requirement_hcloud"></a> [hcloud](#requirement\_hcloud) | = 1.60.1 |
| <a name="requirement_random"></a> [random](#requirement\_random) | = 3.8.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_random"></a> [random](#provider\_random) | = 3.8.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_control_plane"></a> [control\_plane](#module\_control\_plane) | ./modules/_control_plane | n/a |
| <a name="module_network"></a> [network](#module\_network) | ./modules/_network | n/a |
| <a name="module_readiness"></a> [readiness](#module\_readiness) | ./modules/_readiness | n/a |

## Resources

| Name | Type |
|------|------|
| [random_password.cluster_token](https://registry.terraform.io/providers/hashicorp/random/3.8.1/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name prefix for all created resources. Must be lowercase alphanumeric with hyphens, 3-63 characters. | `string` | n/a | yes |
| <a name="input_control_plane_nodes"></a> [control\_plane\_nodes](#input\_control\_plane\_nodes) | Map of control plane node definitions. Keys are node identifiers, values configure each server. | <pre>map(object({<br/>    # NOTE: cx22 retired by Hetzner 2026 — replaced with cx23 (same specs).<br/>    server_type = optional(string, "cx23")<br/>    location    = optional(string)<br/>    labels      = optional(map(string), {})<br/>    backups     = optional(bool, false)<br/>  }))</pre> | <pre>{<br/>  "cp-0": {},<br/>  "cp-1": {},<br/>  "cp-2": {}<br/>}</pre> | no |
| <a name="input_create"></a> [create](#input\_create) | Controls whether any resources are created. Set to false to disable the entire module. | `bool` | `true` | no |
| <a name="input_delete_protection"></a> [delete\_protection](#input\_delete\_protection) | Enable deletion protection on servers and load balancers. | `bool` | `false` | no |
| <a name="input_enable_cis"></a> [enable\_cis](#input\_enable\_cis) | Enable RKE2 CIS hardening. Creates etcd user, sets required kernel params, and adds 'profile: cis' to config.yaml. Safe on both stock images and Packer golden images (prerequisites are idempotent). | `bool` | `false` | no |
| <a name="input_existing_network_id"></a> [existing\_network\_id](#input\_existing\_network\_id) | ID of an existing Hetzner Cloud network. When set, network creation is skipped (BYO network). | `number` | `null` | no |
| <a name="input_extra_server_manifests"></a> [extra\_server\_manifests](#input\_extra\_server\_manifests) | Map of filename => YAML content placed in /var/lib/rancher/rke2/server/manifests/. RKE2 HelmController auto-installs HelmChart CRDs found there. Allows consumers to deploy Helm charts (e.g. cert-manager, Rancher) without direct K8s API access from Terraform. | `map(string)` | `{}` | no |
| <a name="input_firewall_ids"></a> [firewall\_ids](#input\_firewall\_ids) | List of Hetzner firewall IDs to attach to all nodes. BYO: create firewalls externally and pass their IDs. | `list(number)` | `[]` | no |
| <a name="input_hcloud_image"></a> [hcloud\_image](#input\_hcloud\_image) | OS image for all nodes. Must be an Ubuntu 24.04 image name or ID. | `string` | `"ubuntu-24.04"` | no |
| <a name="input_hcloud_location"></a> [hcloud\_location](#input\_hcloud\_location) | Hetzner Cloud datacenter location for servers and resources. | `string` | `"nbg1"` | no |
| <a name="input_hcloud_network_cidr"></a> [hcloud\_network\_cidr](#input\_hcloud\_network\_cidr) | IP range for the private network in CIDR notation. | `string` | `"10.0.0.0/16"` | no |
| <a name="input_hcloud_network_zone"></a> [hcloud\_network\_zone](#input\_hcloud\_network\_zone) | Hetzner Cloud network zone. Must match the hcloud\_location's region. | `string` | `"eu-central"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Common labels applied to all created resources. Merged with node-specific labels. | `map(string)` | `{}` | no |
| <a name="input_rke2_config"></a> [rke2\_config](#input\_rke2\_config) | Additional RKE2 config.yaml content appended to every node's configuration. | `string` | `""` | no |
| <a name="input_rke2_version"></a> [rke2\_version](#input\_rke2\_version) | RKE2 version to install. Empty string uses the upstream stable channel (less reproducible). | `string` | `"v1.34.4+rke2r1"` | no |
| <a name="input_ssh_key_ids"></a> [ssh\_key\_ids](#input\_ssh\_key\_ids) | List of existing Hetzner SSH key IDs to inject into nodes. Default empty = True Zero-SSH. BYO: pass your pre-created key IDs. | `list(number)` | `[]` | no |
| <a name="input_subnet_address"></a> [subnet\_address](#input\_subnet\_address) | IP range for the subnet in CIDR notation. Must be within hcloud\_network\_cidr. | `string` | `"10.0.1.0/24"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_ready"></a> [cluster\_ready](#output\_cluster\_ready) | Boolean indicating the cluster API server is responsive. |
| <a name="output_cluster_token"></a> [cluster\_token](#output\_cluster\_token) | RKE2 cluster registration token. |
| <a name="output_control_plane_ipv4_addresses"></a> [control\_plane\_ipv4\_addresses](#output\_control\_plane\_ipv4\_addresses) | Map of node key to public IPv4 address for control plane nodes. |
| <a name="output_control_plane_private_ipv4_addresses"></a> [control\_plane\_private\_ipv4\_addresses](#output\_control\_plane\_private\_ipv4\_addresses) | Map of node key to private IPv4 address for control plane nodes. |
| <a name="output_control_plane_server_ids"></a> [control\_plane\_server\_ids](#output\_control\_plane\_server\_ids) | Map of node key to Hetzner server ID for control plane nodes. |
| <a name="output_initial_master_ipv4"></a> [initial\_master\_ipv4](#output\_initial\_master\_ipv4) | Public IPv4 address of the initial master (cluster bootstrap node). |
| <a name="output_network_id"></a> [network\_id](#output\_network\_id) | ID of the private network (created or BYO). |
| <a name="output_network_subnet_id"></a> [network\_subnet\_id](#output\_network\_subnet\_id) | ID of the subnet. |
<!-- END_TF_DOCS -->
