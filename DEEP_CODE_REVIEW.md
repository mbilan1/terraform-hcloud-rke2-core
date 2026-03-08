# Deep Code Review: terraform-hcloud-rke2-core

**Date**: 2026-03-07
**Reviewer**: Automated Deep Review (Claude)
**Overall Score**: 8.5/10

## Executive Summary

Well-engineered Terraform module with thoughtful zero-SSH design, composable primitives, and BYO patterns. Critical findings are primarily documentation staleness (auto-generated docs not regenerated after version bumps) and validation gaps.

**Total Issues: 14** — 0 Critical, 2 High, 5 Medium, 7 Low

---

## High Severity Issues

### 1. Stale Auto-Generated Documentation — RKE2 Version

- **Files**: `README.md` (shows `v1.32.2+rke2r1`), `modules/_control_plane/README.md` (shows `v1.32.2+rke2r1`)
- **Actual default**: `variables.tf:165` → `v1.34.4+rke2r1`
- **Impact**: Users misled about deployed RKE2 version.
- **Fix**: Regenerate terraform-docs (`<!-- BEGIN_TF_DOCS -->` sections).

### 2. Dead `worker_nodes` Variable in README

- **File**: `README.md` (auto-generated section)
- **Impact**: README documents a `worker_nodes` variable that was removed (confirmed in `CHANGELOG.md:29`). Users will try to use a non-existent variable.
- **Fix**: Regenerate terraform-docs.

---

## Medium Severity Issues

### 3. No Checksum Verification for RKE2 Install

- **File**: `modules/_control_plane/templates/cloud-init.yaml.tftpl:48-50`
- `curl -sfL https://get.rke2.io | sh -` — pipes directly to shell. Standard upstream method, but trust-on-first-use (TOFU) security model with no checksum or signature verification.
- **Fix**: Add SHA-256 checksum verification of the install script, or at minimum document HTTPS-only verification, network security requirements, and the accepted TOFU risk.

### 4. `ignore_changes` on `user_data` Breaks Drift Detection

- **File**: `modules/_control_plane/main.tf:77-89`
- Cloud-init changes, SSH key modifications, image updates not detected by Terraform. Documented as COMPROMISE with TODO.
- **Fix**: Document limitation prominently in README.

### 5. Cluster Token in State Unencrypted

- **File**: `outputs.tf:49-53`
- Token marked `sensitive = true` (hides CLI output), but stored unencrypted in `terraform.tfstate` by default.
- **Fix**: Add state encryption guidance to README.

### 6. No Subnet CIDR Containment Validation

- **File**: `variables.tf:67-89`, `guardrails.tf`
- Individual CIDR syntax validated, but no check that subnet is within network CIDR.
- **Fix**: Add check block to `guardrails.tf`.

### 7. Missing State Encryption Documentation

- **File**: `README.md`
- No guidance on backend encryption, state access control, or disaster recovery for state.
- **Fix**: Add "State Management & Security" section.

---

## Low Severity Issues

### 8. No YAML Validation for `extra_server_manifests`

- **File**: `variables.tf:181-186`
- Accepts arbitrary `map(string)` with no YAML syntax validation. Invalid YAML fails silently at bootstrap.
- **Fix**: Enhance variable description with format requirements.

### 9. Missing Minimum Firewall Rules Documentation

- **Files**: `examples/complete/main.tf:47-48`, `README.md`
- BYO firewall pattern without specifying required ports (6443, 9345, 51820, 10250).
- **Fix**: Document minimum RKE2 firewall rules in README or examples.

### 10. No Backup Strategy Guidance

- **File**: `variables.tf:136`
- `backups = true` supported per-node but no documentation on when to enable, cost, or restore procedures.
- **Fix**: Add backup guidance to README.

### 11. Limited RKE2 Version Test Coverage

- **File**: `tests/variables.tftest.hcl:274-284`
- Tests valid/invalid versions but misses edge cases (missing `+rke2r` suffix, pre-release versions).
- **Fix**: Add additional test cases.

### 12-14. Minor Issues

- Join address implicit dependency (documented as Compromise #C2 in `docs/ARCHITECTURE.md`)
- No SSH key strength validation (acceptable — keys are optional)
- Cloud-init conditional comment in output YAML (trivial noise)

---

## Strengths

- Composable architecture: 3 independent primitives (_network, _control_plane, _readiness)
- Comprehensive variable validation with regex and cross-variable checks
- Zero-SSH design: no provisioners, no key generation, immutable bootstrap
- BYO patterns for network and firewall (multi-cluster support)
- 26 unit tests with mock providers (~3s execution, zero cloud costs)
- Preflight checks via `check` blocks (location/zone, etcd quorum, delete protection)
- Provider minimalism: only 2 providers (hcloud, random) vs 6 in v1
- Well-commented code with DECISION/COMPROMISE/NOTE/TODO prefixes
- Pre-commit hooks for fmt, validate, tflint, docs

---

## Fix Verification Status (2026-03-07)

Verified against commit `5b8b31f` ("fix: resolve code review findings") on `main`.

| # | Issue | Severity | Status | Notes |
|---|-------|----------|--------|-------|
| 1 | Stale RKE2 version in README | High | **PARTIAL** | Code updated to v1.34.4; terraform-docs not regenerated, README still shows v1.32.2 |
| 2 | Dead worker_nodes in README | High | **NOT FIXED** | terraform-docs not regenerated; stale variable still in auto-generated docs |
| 3 | No checksum for RKE2 install | Medium | **ACCEPTED** | Upstream curl\|sh method; documented as acceptable risk |
| 4 | ignore_changes breaks drift | Medium | **PARTIAL** | COMPROMISE comment added; README not updated |
| 5 | Cluster token in state | Medium | **PARTIAL** | ARCHITECTURE.md updated with state security note |
| 6 | No subnet CIDR containment | Medium | **PARTIAL** | Syntax validation added; containment check not in guardrails.tf |
| 7 | Missing state encryption docs | Medium | **NOT FIXED** | No "State Management & Security" section in README |
| 8 | No YAML validation for manifests | Low | **PARTIAL** | Variable description enhanced with format requirements |
| 9 | Missing firewall rules docs | Low | **PARTIAL** | Comment added; no README documentation |
| 10 | No backup strategy guidance | Low | **NOT FIXED** | No backup documentation added |
| 11 | Limited RKE2 version tests | Low | **FIXED** | 3 new test cases added for edge cases |
| 12 | Stale SSH key comment | Low | **FIXED** | Comment updated to reflect True Zero-SSH |
| 13 | Readiness timeout | Low | **FIXED** | Timeout value and documentation corrected |
| 14 | Label duplication | Trivial | **FIXED** | Duplicate labels removed |

**Summary**: 4/14 fully fixed, 6 partial, 3 not fixed, 1 accepted as-is.
