# Claude Instructions — terraform-hcloud-rke2-core

> Claude-specific context. Read [AGENTS.md](AGENTS.md) first — it contains the universal rules.
> This file adds Claude-specific workflow patterns and deep architectural context.

---

## Quick Reference

- **22 tests**, mock_provider, ~3s, $0: `tofu test`
- **Validate**: `tofu validate` (safe, always run after edits)
- **Format**: `tofu fmt` (safe, auto-fix)
- **NEVER**: `tofu plan` in root, `tofu apply`, `tofu destroy`, `tofu init -upgrade`

---

## Architecture Knowledge Base

Platform-wide decisions are documented in a separate repository:
- **Repo**: [rke2-hetzner-architecture](https://github.com/mbilan1/rke2-hetzner-architecture)
- Contains: ADRs (5), investigation reports (3), design documents (2)
- Key ADRs: True Zero-SSH (002), Dual LB (003), Shared Network (005)

---

## Module Dependency Graph

```
Root facade (main.tf)
  ├── modules/_network/    → hcloud_network + hcloud_network_subnet
  ├── modules/_firewall/   → hcloud_firewall (cp_rules + worker_rules)
  ├── modules/_control_plane/  → hcloud_server + hcloud_server_network + cloudinit
  └── modules/_readiness/  → terraform_data (HTTPS poll on :6443/readyz)
```

Each primitive: `create` bool → `for_each` gating → BYO via `existing_*` vars.

---

## HCL Patterns in This Repo

### for_each gating (NOT count)
```hcl
resource "hcloud_network" "this" {
  for_each = var.create ? { "main" = true } : {}
  # ...
}
```

### BYO resource pattern
```hcl
output "network_id" {
  value = var.create ? hcloud_network.this["main"].id : var.existing_network_id
}
```

### Variable validation
```hcl
variable "control_plane_nodes" {
  type = map(object({ ... }))
  validation {
    condition     = length(var.control_plane_nodes) != 2
    error_message = "2-node clusters cause etcd split-brain."
  }
}
```

### Guardrails (check blocks in guardrails.tf)
```hcl
check "location_zone_consistency" {
  assert {
    condition     = <cross-variable validation>
    error_message = "..."
  }
}
```

### Test pattern (mock_provider)
```hcl
run "test_name" {
  command = plan
  variables { ... }
  expect_failures = [var.control_plane_nodes]  # for negative tests
}
```

---

## What NOT to Touch

1. **SSH** — True Zero-SSH (ADR-002). No SSH keys, no port 22, no sshd. BYO only via `ssh_key_ids`
2. **Load balancers** — NOT in this module. Consumer creates them (ADR-003)
3. **Worker nodes** — `worker_nodes` var exists for future use, but workers are via Rancher CAS
4. **`tls` provider** — removed. Don't re-add
5. **cloud-init templates** — in `modules/_control_plane/templates/`. Edit carefully — they bootstrap RKE2

---

## Workflow: Adding a New Submodule

1. Create `modules/_name/` with underscore prefix
2. Files: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`
3. Add `create` bool variable for `for_each` gating
4. Add `existing_*` variable for BYO pattern
5. Wire in root `main.tf` facade
6. Add tests in `tests/variables.tftest.hcl` and `tests/guardrails.tftest.hcl`
7. Run full suite: `tofu test`

## Workflow: Editing Variables

1. Edit `variables.tf` (root or submodule)
2. Add/update `validation {}` block if needed
3. Add test case in `tests/variables.tftest.hcl` (positive + negative)
4. If cross-variable: add `check {}` in `guardrails.tf` + test in `tests/guardrails.tftest.hcl`
5. Run: `tofu validate && tofu test`

---

## Language

- **Code & comments**: English
- **Commits**: English, Conventional Commits
- **User communication**: respond in the user's language
