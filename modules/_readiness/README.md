# _readiness

Cluster health check via HTTPS polling against the Kubernetes API server.

Uses `local-exec` with `curl` to poll `https://{ip}:6443/readyz` — no SSH
required. Part of the zero-SSH design philosophy.

<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [terraform_data.wait_for_api](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_initial_master_ipv4"></a> [initial\_master\_ipv4](#input\_initial\_master\_ipv4) | Public IPv4 address of the initial master node. | `string` | n/a | yes |
| <a name="input_create"></a> [create](#input\_create) | Controls whether readiness checks are executed. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_ready_id"></a> [api\_ready\_id](#output\_api\_ready\_id) | ID of the readiness check resource. Use as depends\_on target. |
| <a name="output_cluster_ready"></a> [cluster\_ready](#output\_cluster\_ready) | Boolean indicating the cluster API server is reachable. Depends on the HTTPS readiness check completing. |
<!-- END_TF_DOCS -->
