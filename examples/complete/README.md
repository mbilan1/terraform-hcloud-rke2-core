# Complete Example

Deploys a full HA RKE2 cluster with 3 control plane nodes,
custom networking, BYO firewall, and deletion protection.

## Prerequisites

- Hetzner Cloud API token
- OpenTofu >= 1.8.0

## Usage

```bash
export HCLOUD_TOKEN="your-token-here"
tofu init
tofu plan
tofu apply
```

## Features Demonstrated

- **HA Control Plane**: 3 nodes for etcd quorum
- **Custom Network**: Non-default IP ranges
- **BYO Firewall**: Pre-created Hetzner firewall passed via `firewall_ids` (ADR-006)
- **Deletion Protection**: Prevents accidental resource destruction
- **Labels**: Environment and team tags for resource organization

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0 |
| <a name="requirement_hcloud"></a> [hcloud](#requirement\_hcloud) | ~> 1.49 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_hcloud"></a> [hcloud](#provider\_hcloud) | ~> 1.49 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_rke2"></a> [rke2](#module\_rke2) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [hcloud_firewall.rke2](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/firewall) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_hcloud_token"></a> [hcloud\_token](#input\_hcloud\_token) | Hetzner Cloud API token. Prefer setting via HCLOUD\_TOKEN env var. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_ready"></a> [cluster\_ready](#output\_cluster\_ready) | Whether the cluster API is responding. |
| <a name="output_control_plane_ips"></a> [control\_plane\_ips](#output\_control\_plane\_ips) | Public IPs of all control plane nodes. |
<!-- END_TF_DOCS -->