# Complete Example

Deploys a full HA RKE2 cluster with 3 control plane nodes, 2 workers,
custom networking, security hardening, and deletion protection.

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
- **Workers**: 2 nodes with heterogeneous server types
- **Custom SSH Port**: 2222 (non-standard for scanner avoidance)
- **Restricted Access**: SSH and API limited to private CIDRs
- **Custom Network**: Non-default IP ranges
- **Deletion Protection**: Prevents accidental resource destruction
- **Labels**: Environment and team tags for resource organization
