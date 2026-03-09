# Claude Instructions — terraform-hcloud-rke2-core

> Single source of truth for AI agents working on this repository.
> AGENTS.md redirects here. Read this file in full before any task.

---

## ⚠️ MANDATORY: Read ARCHITECTURE.md First

**Before making ANY change**, read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) in full.

It contains:
- Composable primitive architecture (facade + 3 submodules)
- Zero-SSH design philosophy
- BYO resource pattern
- Dependency chain (network → control_plane → readiness)
- Provider strategy (2 providers only)
- Compromise Log

**If you skip ARCHITECTURE.md, you WILL break something.**

---

## What This Repository Is

An **OpenTofu/Terraform module** (NOT a root deployment) that provisions **L3 infrastructure** for an RKE2 Kubernetes cluster on Hetzner Cloud.

- **IaC tool**: OpenTofu >= 1.8.0 — always use `tofu`, **never** `terraform`
- **Cloud provider**: Hetzner Cloud
- **Layer**: L3 only — servers, network, readiness
- **OS**: Ubuntu 24.04 LTS
- **Design**: Zero-SSH, composable primitives, BYO resources
- **Status**: Active development

### What This Module Does NOT Do

| Out of scope | Where it lives |
|---|---|
| Kubernetes addons (HCCM, CSI, cert-manager) | `terraform-hcloud-rancher` or Helmfile |
| Kubeconfig retrieval | `terraform-hcloud-rancher` (Rancher API) |
| SSH key generation | Removed — True Zero-SSH. Use `ssh_key_ids` for BYO |
| Worker nodes | Out of scope — workers via Rancher CAS |
| DNS | Operator's responsibility |

---

## Sibling Repositories

| Repo | Purpose |
|---|---|
| `terraform-hcloud-rancher` | Management cluster that USES this module as L3 base |
| `rke2-hetzner-architecture` | Architecture decisions + investigation reports |
| `rancher-hetzner-cluster-templates` | Downstream cluster Helm templates |

---

## Quick Reference

- **31 tests**, mock_provider, ~3s, $0: `tofu test`
- **Validate**: `tofu validate` (safe, always run after edits)
- **Format**: `tofu fmt` (safe, auto-fix)
- **NEVER**: `tofu plan` in root, `tofu apply`, `tofu destroy`, `tofu init -upgrade`

---

## Critical Rules

### NEVER do these:
1. **Do NOT run `tofu plan` in the root module** — root is a reusable module, not a deployment
2. **Do NOT run `tofu apply`** — provisions real infrastructure and costs money
3. **Do NOT run `tofu destroy`** — destroys infrastructure
4. **Do NOT run `tofu init -upgrade`** — modifies `.terraform.lock.hcl` silently
5. **Do NOT change providers** without explicit user request AND live verification
6. **Do NOT modify `terraform.tfstate`** or `.terraform.lock.hcl` directly
7. **Do NOT commit secrets**, API keys, tokens, or private SSH keys
8. **Do NOT rewrite README.md** — it has auto-generated `terraform-docs` sections between markers
9. **Do NOT add SSH back** — True Zero-SSH is a deliberate decision (ADR-002). No SSH keys, no SSH firewall rules, no sshd config.
10. **A question is NOT a request to change code.**

### ALWAYS do these:
1. **Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** before any structural change
2. **Run `tofu validate`** after any `.tf` file change
3. **Run `tofu fmt -check`** to verify formatting
4. **Run `tofu test`** after changes to variables, guardrails, or conditional logic
5. **Preserve existing code comments** — they document deliberate compromises
6. **Read the relevant file before editing**
7. **Verify external claims via network** before suggesting changes

### Where to run what

| Command | Root module (`/`) | `examples/*` directories |
|---------|:-:|:-:|
| `tofu validate` | ✅ Safe | ✅ Safe |
| `tofu fmt` | ✅ Safe | ✅ Safe |
| `tofu test` | ✅ Safe (uses mock_provider) | N/A |
| `tofu plan` | ❌ **Forbidden** | ✅ With credentials |
| `tofu apply` | ❌ **Forbidden** | ⚠️ Only with explicit user approval |

### Safe commands (can run without asking):
- `tofu validate`, `tofu fmt`, `tofu test`
- `grep`, `cat`, `head`, `tail`, `wc` — read-only
- `git diff`, `git log`, `git status` — read-only

---

## Verification Rules (MANDATORY)

> **Your training data is outdated. Never trust it for version numbers, deprecation status, or API compatibility.**

Before making changes involving external dependencies:
1. **Providers** — check live Terraform Registry or GitHub releases
2. **Hetzner server types** — verify via `https://api.hetzner.cloud/v1/server_types`
3. **Hetzner locations** — verify via `https://api.hetzner.cloud/v1/locations`

### Structured comparison format

When comparing options, present **facts-first in a table** BEFORE conclusions. Re-read the table before writing conclusions — if the narrative contradicts a fact, the narrative is wrong.

### If you cannot verify:
- Say so explicitly
- Do NOT make changes based on unverified assumptions

---

## Repository Structure

### Root Module (Thin Facade)

| File | Purpose |
|------|---------|
| `main.tf` | Facade — wires 3 primitives: network → control_plane → readiness |
| `variables.tf` | All user-facing input variables with validations |
| `outputs.tf` | Module outputs (IPs, network ID, cluster token) |
| `guardrails.tf` | Preflight `check {}` blocks (location/zone, CIDR safety) |
| `versions.tf` | Provider constraints: hcloud = 1.60.1, random = 3.8.1 |

### Submodules (Composable Primitives)

| Module | Purpose | BYO Variable |
|--------|---------|---|
| `modules/_network/` | Hetzner private network + subnet | `existing_network_id` |
| `modules/_control_plane/` | Servers + cloud-init + network attachment | — |
| `modules/_readiness/` | HTTPS polling on port 6443 | — |

**Underscore prefix** (`_`) signals "internal" — consumers use the root facade.

> **Firewall**: Removed from module per ADR-006 (BYO Firewall). Consumers pass `firewall_ids` directly.

### Other Directories

| Path | Purpose |
|------|---------|
| `docs/ARCHITECTURE.md` | Full architecture documentation — **READ FIRST** |
| `examples/minimal/` | 1-node dev cluster example |
| `examples/complete/` | 3-node HA cluster with all knobs |
| `tests/` | Unit tests (mock_provider, ~3s) |

---

## Module Dependency Graph

```
Root facade (main.tf)
  ├── modules/_network/    → hcloud_network + hcloud_network_subnet
  ├── modules/_control_plane/  → hcloud_server + hcloud_server_network + cloudinit
  └── modules/_readiness/  → terraform_data (HTTPS poll on :6443/readyz)
```

Each primitive: `create` bool → `for_each` gating → BYO via `existing_*` vars.

---

## Architecture Constraints

### True Zero-SSH (ADR-002)
- **NO** SSH key auto-generation (tls provider removed)
- **NO** SSH firewall rules (port 22 not opened)
- **NO** sshd cloud-init configuration
- **YES** `ssh_key_ids` variable for BYO (default: `[]`)
- Readiness check: `curl -sk https://{ip}:6443/readyz`

### Composable Primitives
- Each submodule has `create` boolean for `for_each` gating
- BYO resources via `existing_*` variables (skip creation, use provided IDs)
- `for_each` over `count` — stable identity, heterogeneous configs
- Root facade wires: `network → control_plane → readiness`

### BYO Firewall (ADR-006)
- Firewalls are NOT managed by this module
- Consumers create Hetzner firewalls externally and pass IDs via `firewall_ids`
- Why: Hetzner firewalls are account-level singletons with per-server attachment

### Dual Load Balancer (ADR-003)
- This module does NOT create load balancers
- LBs are separate concerns — created by the consumer (`terraform-hcloud-rancher` or operator)
- CP LB: ports 6443, 9345 → control plane nodes
- Ingress LB: ports 80, 443 → application traffic

### HA Defaults
- `control_plane_nodes` defaults to 3 nodes (`cp-0`, `cp-1`, `cp-2`)
- Single-node clusters require explicit override (see `examples/minimal/`)
- 2-node clusters are blocked (etcd split-brain)

### Provider Strategy
- **2 providers only**: `hcloud` (= 1.60.1) + `random` (= 3.8.1)
- `tls` provider was removed (True Zero-SSH)
- No Kubernetes providers — pure L3

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
3. **`tls` provider** — removed. Don't re-add
4. **cloud-init templates** — in `modules/_control_plane/templates/`. Edit carefully — they bootstrap RKE2

---

## Code Style and Conventions

- **HCL formatting**: `tofu fmt` canonical style
- **Variable naming**: `snake_case`, grouped by concern
- **Comments**: `DECISION:`, `COMPROMISE:`, `WORKAROUND:`, `NOTE:`, `TODO:` prefixes
- **Every new resource needs a WHY comment**
- **Outputs**: `sensitive = true` for credentials
- **`nullable = false`** on all variables
- **pre-commit**: `terraform_fmt`, `terraform_validate`, `terraform_tflint`, `terraform_docs`, `conventional-pre-commit`

### Git Commit Convention

Conventional Commits format, English only:
```
<type>(<scope>): <short summary>
```
Types: `feat`, `fix`, `docs`, `refactor`, `chore`, `style`, `test`, `ci`
Scope: `network`, `firewall`, `control-plane`, `readiness`, `examples`, `providers`

### Comment Prefixes

```hcl
# DECISION: <what was decided>
# Why: <rationale>
# See: <link>

# COMPROMISE: <trade-off>
# Why: <reason ideal isn't possible>

# WORKAROUND: <what bug this works around>
# TODO: Remove when <condition>

# NOTE: <non-obvious context>
# TODO: <planned improvement>
```

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

## Common Pitfalls

1. **Root module is not runnable** — use `examples/` for plan/apply
2. **cx22 is dead** — Hetzner retired it. Use cx23 (same specs: 2 vCPU, 4 GB)
3. **README.md has auto-generated sections** — don't edit between `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->`
4. **`terraform.tfstate` should NEVER be committed**
5. **Questions ≠ change requests** — answer questions with evidence, don't edit code unless explicitly asked
6. **SSH was deliberately removed** — don't re-add SSH-related variables, firewall rules, or cloud-init blocks
7. **Training data is stale** — always verify server types, locations, and provider versions via live API

---

## Architecture Knowledge Base

Platform-wide decisions are documented in a separate repository:
- **Repo**: [rke2-hetzner-architecture](https://github.com/mbilan1/rke2-hetzner-architecture)
- Contains: ADRs (8), investigation reports (3), design documents (2)
- Key ADRs: True Zero-SSH (002), Dual LB (003), Shared Network (005), CAPI Autoscaler (008)

---

## Workflow: Updating Version Badges

README.md contains version badges (shields.io) that must stay in sync with `versions.tf`.

| Badge | Source of truth | Badge URL parameter |
|---|---|---|
| OpenTofu | `versions.tf` → `required_version` | `OpenTofu-<version>` |
| hcloud | `versions.tf` → `required_providers.hcloud.version` | `hcloud-<version>` |
| random | `versions.tf` → `required_providers.random.version` | `random-<version>` |
| RKE2 | `variables.tf` → `rke2_version` default | `RKE2-<version>` |

When bumping a provider version:
1. Update `versions.tf`
2. Update the matching badge URL in README.md (search for `img.shields.io/badge/<name>`)
3. Run `tofu validate && tofu test`

---

## Language

- **Code & comments**: English
- **Commits**: English, Conventional Commits
- **User communication**: respond in the user's language

---

## Reference Resources

### Terraform Module Development

- [HashiCorp — Module Development](https://developer.hashicorp.com/terraform/language/modules/develop) — official guide: structure, standard layout, publishing
- [Terraform Best Practices](https://www.terraform-best-practices.com/) — community guide by Anton Babenko: naming, structure, composition
- [terraform-skill](https://github.com/antonbabenko/terraform-skill) — Claude/AI skill for Terraform coding conventions and module design
- [DevOpsCube — Module Best Practices](https://devopscube.com/terraform-module-best-practices/) — variable design, output conventions, testing

### RKE2 & Hetzner Cloud

- [RKE2 Documentation](https://docs.rke2.io/) — installation, configuration, networking, security
- [RKE2 Server Configuration](https://docs.rke2.io/reference/server_config) — all control-plane config options
- [RKE2 CIS Hardening](https://docs.rke2.io/security/hardening_guide) — CIS Benchmark compliance
- [Hetzner Cloud API](https://docs.hetzner.cloud/) — servers, networks, firewalls, LBs
- [hcloud-cloud-controller-manager](https://github.com/hetznercloud/hcloud-cloud-controller-manager) — Hetzner CCM
- [hcloud-csi-driver](https://github.com/hetznercloud/csi-driver) — Hetzner CSI

> Full reference list: see [rke2-hetzner-architecture](https://github.com/mbilan1/rke2-hetzner-architecture) README.md
