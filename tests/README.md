# Tests

Unit tests for the terraform-hcloud-rke2-core module.

## Running Tests

```bash
# All tests (~3s, $0, no credentials needed)
tofu test

# Single test file
tofu test -filter=tests/variables.tftest.hcl
tofu test -filter=tests/guardrails.tftest.hcl
```

## Test Files

| File | Tests | Scope |
|------|:-----:|-------|
| `variables.tftest.hcl` | 23 | Variable validation (positive + negative) |
| `guardrails.tftest.hcl` | 10 | Cross-variable check blocks |

## Design

- All tests use `command = plan` with `mock_provider` (auto-mocking)
- Zero cloud credentials required
- Zero infrastructure provisioned
- Runs in ~3 seconds

## Quality Gate Pipeline

```
Gate 0 ─ Static Analysis     fmt · validate · tflint · Checkov · KICS · tfsec
Gate 1 ─ Unit Tests           variables · guardrails
Gate 2 ─ Integration          tofu plan against real providers (requires secrets)
Gate 3 ─ E2E                  tofu apply + smoke tests + destroy (manual only)
```

| Gate | Badge | Workflow | Trigger | Cost |
|:----:|-------|----------|---------|:----:|
| 0a | Lint: fmt | `lint-fmt.yml` | push + PR | $0 |
| 0a | Lint: validate | `lint-validate.yml` | push + PR | $0 |
| 0a | Lint: tflint | `lint-tflint.yml` | push + PR | $0 |
| 0b | SAST: Checkov | `sast-checkov.yml` | push + PR | $0 |
| 0b | SAST: KICS | `sast-kics.yml` | push + PR | $0 |
| 0b | SAST: tfsec | `sast-tfsec.yml` | push + PR | $0 |
| 1 | Unit: variables | `unit-variables.yml` | push + PR | $0 |
| 1 | Unit: guardrails | `unit-guardrails.yml` | push + PR | $0 |
| 2 | Integration: plan | `integration-plan.yml` | PR + manual | $0 (plan) |
| 3 | E2E: apply | `e2e-apply.yml` | Manual only | ~$0.50/run |
