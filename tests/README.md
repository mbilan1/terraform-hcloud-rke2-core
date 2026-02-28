# Tests

Unit tests for the terraform-hcloud-ubuntu-rke2-v2 module.

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
| `variables.tftest.hcl` | 16 | Variable validation (positive + negative) |
| `guardrails.tftest.hcl` | 5 | Cross-variable check blocks |

## Design

- All tests use `command = plan` with `mock_provider` (auto-mocking)
- Zero cloud credentials required
- Zero infrastructure provisioned
- Runs in ~3 seconds
