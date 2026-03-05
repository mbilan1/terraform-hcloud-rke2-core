# _network

Private network and subnet primitive with BYO (Bring Your Own) support.

When `existing_network_id` is provided, no resources are created — the module
simply passes the existing ID through.

<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0 |
| <a name="requirement_hcloud"></a> [hcloud](#requirement\_hcloud) | >= 1.49 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_hcloud"></a> [hcloud](#provider\_hcloud) | >= 1.49 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [hcloud_network.this](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/network) | resource |
| [hcloud_network_subnet.this](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/network_subnet) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | Name prefix for the network resource. | `string` | n/a | yes |
| <a name="input_create"></a> [create](#input\_create) | Controls whether network resources are created. | `bool` | `true` | no |
| <a name="input_delete_protection"></a> [delete\_protection](#input\_delete\_protection) | Enable deletion protection on the network. | `bool` | `false` | no |
| <a name="input_existing_network_id"></a> [existing\_network\_id](#input\_existing\_network\_id) | ID of an existing network. When set, no network is created. | `number` | `null` | no |
| <a name="input_hcloud_network_zone"></a> [hcloud\_network\_zone](#input\_hcloud\_network\_zone) | Hetzner Cloud network zone for the subnet. | `string` | `"eu-central"` | no |
| <a name="input_ip_range"></a> [ip\_range](#input\_ip\_range) | IP range for the network in CIDR notation. | `string` | `"10.0.0.0/16"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels to apply to the network. | `map(string)` | `{}` | no |
| <a name="input_subnet_address"></a> [subnet\_address](#input\_subnet\_address) | IP range for the subnet in CIDR notation. | `string` | `"10.0.1.0/24"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_hcloud_network_cidr"></a> [hcloud\_network\_cidr](#output\_hcloud\_network\_cidr) | IP range of the network. |
| <a name="output_network_id"></a> [network\_id](#output\_network\_id) | ID of the network (created or existing). |
| <a name="output_subnet_id"></a> [subnet\_id](#output\_subnet\_id) | ID of the created subnet. Null when using an existing network. |
<!-- END_TF_DOCS -->
