# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.2] - 2026-04-02

### Fixed

- **HA etcd join failure**: Added `node-ip` detection via Hetzner Metadata Service in cloud-init. Without `node-ip`, RKE2 defaults to the public IP for etcd peer URLs — port 2380 is blocked by Hetzner Firewall on the public interface, causing joining nodes to loop on `MemberAdd` indefinitely. The fix resolves private IP at boot and injects it into `config.yaml` before RKE2 starts (INV-005)

### Added

- **CIS hardening**: `enable_cis` variable — single feature flag for RKE2 CIS 1.23 profile (ADR-011)
- **CIS cloud-init prereqs**: Idempotent etcd user/group creation, kernel sysctl params, audit directory — safe with both stock and Packer-baked images
- **CI/CD**: Gate 0 (lint + SAST) and Gate 1 (unit tests) GitHub Actions workflows (ADR-010)
- **examples/complete/**: BYO firewall resource demonstrating ADR-006 pattern (ICMP, 6443, 9345 rules)
- **Tests**: Expanded from 19 to 33 unit tests (CIS variable tests, guardrails coverage)

### Fixed

- **create=false bug**: `network_id` output was `null` when `create = false` due to `for_each` empty map — added `try()` fallback
- **CI**: tfsec workflow `continue-on-error` for `check {}` blocks that tfsec cannot parse

### Changed

- **Module source**: `examples/` switched from local `source = "../.."` to git reference `v0.1.0` for stability
- **Docs**: Regenerated terraform-docs, fixed CIS profile references in ARCHITECTURE.md
- **CI**: Bumped `opentofu/setup-opentofu` 1.0.8 → 2.0.0, `bridgecrewio/checkov-action` 12.3088.0 → 12.3089.0

## [0.1.0] - 2026-03-06

### Added

- Initial module implementation with composable primitive architecture
- 3 submodules: `_network`, `_control_plane`, `_readiness`
- BYO (Bring Your Own) support for network and firewall
- BYO SSH key injection via `ssh_key_ids` (True Zero-SSH by default)
- HA control plane with `for_each`-based node identity
- Zero-SSH design — readiness via HTTPS polling, no remote-exec, no key generation
- Cross-variable guardrails via `check {}` blocks
- 19 unit tests with `mock_provider` (zero credentials, ~3s)
- Pre-commit hooks (fmt, validate, tflint, terraform-docs, conventional-commits)

### Changed

- **RKE2 default**: Bumped to v1.34.4+rke2r1
- **Readiness timeout**: Reduced to 6m (Packer baked images boot faster)

### Removed

- Dead `worker_nodes` variable (workers out of scope — ADR-001)
