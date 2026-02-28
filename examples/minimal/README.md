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

```bash
# Get SSH key
tofu output -raw ssh_private_key > ~/.ssh/rke2-minimal.pem
chmod 600 ~/.ssh/rke2-minimal.pem

# SSH into the node
ssh -i ~/.ssh/rke2-minimal.pem root@$(tofu output -raw initial_master_ip)

# Get kubeconfig
ssh -i ~/.ssh/rke2-minimal.pem root@$(tofu output -raw initial_master_ip) cat /etc/rancher/rke2/rke2.yaml
```
