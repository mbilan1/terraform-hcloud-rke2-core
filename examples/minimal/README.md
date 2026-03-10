# Minimal Example

Deploys a single-node RKE2 cluster with all defaults.

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

## Access

This module follows the **True Zero-SSH** design (ADR-002) — no SSH keys are generated
and no SSH access is configured. Cluster readiness is verified via HTTPS polling on port 6443.

To access the cluster, use Rancher (if deployed upstream) or connect via the
Hetzner Cloud Console for emergency debugging.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0 |
| <a name="requirement_hcloud"></a> [hcloud](#requirement\_hcloud) | ~> 1.49 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_rke2"></a> [rke2](#module\_rke2) | ../.. | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_hcloud_token"></a> [hcloud\_token](#input\_hcloud\_token) | Hetzner Cloud API token. Prefer setting via HCLOUD\_TOKEN env var. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_initial_master_ip"></a> [initial\_master\_ip](#output\_initial\_master\_ip) | Public IP of the control plane node. |
<!-- END_TF_DOCS -->