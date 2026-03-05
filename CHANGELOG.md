# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
