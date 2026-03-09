# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **CIS hardening**: `enable_cis` variable — single feature flag for RKE2 CIS 1.23 profile (ADR-011)
- **CIS cloud-init prereqs**: Idempotent etcd user/group creation, kernel sysctl params, audit directory — safe with both stock and Packer-baked images
- **CI/CD**: Gate 0 (lint + SAST) and Gate 1 (unit tests) GitHub Actions workflows (ADR-010)
- **examples/complete/**: BYO firewall resource demonstrating ADR-006 pattern (ICMP, 6443, 9345 rules)

### Fixed

- **create=false bug**: `network_id` output was `null` when `create = false` due to `for_each` empty map — added `try()` fallback

### Changed

- **Module source**: `examples/` switched from local `source = "../.."` to git reference `v0.1.0` for stability

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

- Dead `worker_nodes` variable (workers out of scope — ADR)
