# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.6.0] - 2026-06-18

### Added

- **Initial-node bootstrap reassignment**: Node-side `control_plane_bootstrap_complete` + `control_plane_bootstrap_join_address` variables. After genesis, setting `control_plane_bootstrap_complete = true` makes a RE-PROVISIONED initial control-plane node render as a joining RKE2 server (`is_initial = false`, `server` pointed at a surviving CP peer's private IP) instead of re-running cluster-init. This enables quorum-safe re-provision / OS-migration of the initial CP node **without re-initializing etcd** (avoiding a new empty etcd data-loss SPOF). Peer join is by private IP — explicitly **NO load balancer** of any kind. See ADR-016 L3a.

## [0.5.0] - 2026-06-17

### Changed

- **OS image default**: Bumped from `ubuntu-24.04` to `ubuntu-26.04` (root `var.hcloud_image` + `_control_plane` submodule). NOTE: Ubuntu 26.04 LTS (released 2026-04) is available on Hetzner Cloud (`ubuntu-26.04`, added 2026-05-18) but is **not yet listed in the RKE2 v1.35 / Rancher 2.14 support matrix** (validated: 24.04/22.04/20.04). Adopted per explicit operator requirement; revisit once it appears in the matrix.
- **RKE2 default version**: Bumped to `v1.35.5+rke2r2` (latest patch in the Rancher-2.14.2-certified 1.35 minor). Aligned the version-registry table, `_control_plane` submodule default, and `examples/complete` (were drifted at `v1.34.4`).
- **Providers**: `hcloud` `1.60.1` → `1.65.0`; `random` `3.8.1` → `3.9.0` (root + `_network` + `_control_plane`). README version badges synced.

## [0.4.0] - 2026-04-08

### Changed

- **RKE2 default version**: Bumped from `v1.34.4+rke2r1` to `v1.35.3+rke2r1`

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
