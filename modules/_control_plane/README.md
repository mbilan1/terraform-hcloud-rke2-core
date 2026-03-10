# _control_plane

RKE2 control plane server instances with cloud-init bootstrap.

Creates an initial master (cluster bootstrap node) and joining nodes.
All nodes use `for_each` over a `map(object)` for stable identity —
removing a single node key only destroys that server.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0 |
| <a name="requirement_hcloud"></a> [hcloud](#requirement\_hcloud) | = 1.60.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_hcloud"></a> [hcloud](#provider\_hcloud) | = 1.60.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [hcloud_server.initial](https://registry.terraform.io/providers/hetznercloud/hcloud/1.60.1/docs/resources/server) | resource |
| [hcloud_server.joining](https://registry.terraform.io/providers/hetznercloud/hcloud/1.60.1/docs/resources/server) | resource |
| [hcloud_server_network.initial](https://registry.terraform.io/providers/hetznercloud/hcloud/1.60.1/docs/resources/server_network) | resource |
| [hcloud_server_network.joining](https://registry.terraform.io/providers/hetznercloud/hcloud/1.60.1/docs/resources/server_network) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Cluster name used as prefix for server names. | `string` | n/a | yes |
| <a name="input_cluster_token"></a> [cluster\_token](#input\_cluster\_token) | Shared secret token for RKE2 node registration. | `string` | n/a | yes |
| <a name="input_create"></a> [create](#input\_create) | Controls whether server resources are created. | `bool` | `true` | no |
| <a name="input_delete_protection"></a> [delete\_protection](#input\_delete\_protection) | Enable deletion and rebuild protection on servers. | `bool` | `false` | no |
| <a name="input_enable_cis"></a> [enable\_cis](#input\_enable\_cis) | Enable RKE2 CIS hardening. Creates etcd user, sets kernel params, adds 'profile: cis'. Idempotent on Packer images. | `bool` | `false` | no |
| <a name="input_extra_server_manifests"></a> [extra\_server\_manifests](#input\_extra\_server\_manifests) | Map of filename => YAML content to place in /var/lib/rancher/rke2/server/manifests/. RKE2 HelmController installs HelmChart CRDs found there automatically. | `map(string)` | `{}` | no |
| <a name="input_firewall_ids"></a> [firewall\_ids](#input\_firewall\_ids) | List of firewall IDs to attach to servers. | `list(number)` | `[]` | no |
| <a name="input_hcloud_image"></a> [hcloud\_image](#input\_hcloud\_image) | OS image name or ID for the servers. | `string` | `"ubuntu-24.04"` | no |
| <a name="input_hcloud_location"></a> [hcloud\_location](#input\_hcloud\_location) | Default Hetzner Cloud location for nodes without explicit location. | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Common labels applied to all servers. | `map(string)` | `{}` | no |
| <a name="input_network_id"></a> [network\_id](#input\_network\_id) | Hetzner network ID for private networking. Null when create=false and no BYO network. | `number` | `null` | no |
| <a name="input_nodes"></a> [nodes](#input\_nodes) | Map of control plane node definitions. | <pre>map(object({<br/>    # NOTE: cx22 was retired by Hetzner in early 2026 and is no longer available<br/>    #       for new server creation. cx23 is the direct replacement (same specs:<br/>    #       2 vCPU, 4 GB RAM, 40 GB SSD). Verified via live API 2026-03-01.<br/>    # See: https://docs.hetzner.cloud/ — Server Types<br/>    server_type = optional(string, "cx23")<br/>    location    = optional(string)<br/>    labels      = optional(map(string), {})<br/>    backups     = optional(bool, false)<br/>  }))</pre> | n/a | yes |
| <a name="input_rke2_config"></a> [rke2\_config](#input\_rke2\_config) | Additional RKE2 config.yaml content. | `string` | `""` | no |
| <a name="input_rke2_version"></a> [rke2\_version](#input\_rke2\_version) | RKE2 version to install. | `string` | `"v1.34.4+rke2r1"` | no |
| <a name="input_ssh_key_ids"></a> [ssh\_key\_ids](#input\_ssh\_key\_ids) | List of Hetzner SSH key IDs to attach to servers. | `list(number)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_initial_master_ipv4"></a> [initial\_master\_ipv4](#output\_initial\_master\_ipv4) | Public IPv4 address of the initial master node. |
| <a name="output_initial_master_key"></a> [initial\_master\_key](#output\_initial\_master\_key) | Key of the initial master node (cluster bootstrap node). |
| <a name="output_initial_master_private_ipv4"></a> [initial\_master\_private\_ipv4](#output\_initial\_master\_private\_ipv4) | Private IPv4 address of the initial master node. |
| <a name="output_server_ids"></a> [server\_ids](#output\_server\_ids) | Map of node key to Hetzner server ID. |
| <a name="output_server_ipv4_addresses"></a> [server\_ipv4\_addresses](#output\_server\_ipv4\_addresses) | Map of node key to public IPv4 address. |
| <a name="output_server_private_ipv4_addresses"></a> [server\_private\_ipv4\_addresses](#output\_server\_private\_ipv4\_addresses) | Map of node key to private IPv4 address. |
<!-- END_TF_DOCS -->
