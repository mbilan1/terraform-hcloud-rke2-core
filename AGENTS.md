# AI Agent Instructions

> **READ THIS ENTIRE FILE before touching any code.**
> This file provides mandatory context for AI coding assistants (GitHub Copilot, Claude, Cursor, etc.)
> working with the `terraform-hcloud-rke2-core` module.

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
| Worker nodes | Map exists but unused — workers via Rancher CAS |
| DNS | Operator's responsibility |

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
4. **Run `tofu test`** after changes to variables, guardrails, or conditional logic (19 tests, ~3s, $0)
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
| `versions.tf` | Provider constraints: hcloud ~> 1.49, random ~> 3.6 |

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
| `tests/` | Unit tests (19 tests, mock_provider, ~3s) |

### Test Files

| File | Tests | Scope |
|------|:-----:|-------|
| `variables.tftest.hcl` | 13 | Variable `validation {}` blocks |
| `guardrails.tftest.hcl` | 6 | Cross-variable `check {}` blocks |
| **Total** | **19** | All mock_provider, ~3s, $0 |

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
- **2 providers only**: `hcloud` (~> 1.49) + `random` (~> 3.6)
- `tls` provider was removed (True Zero-SSH)
- No Kubernetes providers — pure L3

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

## Common Pitfalls

1. **Root module is not runnable** — use `examples/` for plan/apply
2. **cx22 is dead** — Hetzner retired it. Use cx23 (same specs: 2 vCPU, 4 GB)
3. **README.md has auto-generated sections** — don't edit between `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->`
4. **`terraform.tfstate` should NEVER be committed**
5. **Questions ≠ change requests** — answer questions with evidence, don't edit code unless explicitly asked
6. **SSH was deliberately removed** — don't re-add SSH-related variables, firewall rules, or cloud-init blocks
7. **`worker_nodes` variable exists but is unused** — workers are provisioned via Rancher CAS, not this module
8. **Training data is stale** — always verify server types, locations, and provider versions via live API

---

## Architecture Knowledge Base

Full architectural context is maintained in a separate repository:
- **Repo**: [rke2-hetzner-architecture](https://github.com/mbilan1/rke2-hetzner-architecture)
- Contains: ADRs, investigation reports, design documents
- Read it for platform-wide context that spans multiple repos

---

## Related Repositories

| Repo | Purpose |
|---|---|
| `terraform-hcloud-rancher` | Management cluster that USES this module as L3 base |
| `rke2-hetzner-architecture` | Architecture decisions + investigation reports |
| `rancher-hetzner-cluster-templates` | Downstream cluster Helm templates |
