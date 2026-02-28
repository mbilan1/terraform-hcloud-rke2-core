# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial module implementation with composable primitive architecture
- 5 submodules: `_network`, `_firewall`, `_ssh_key`, `_control_plane`, `_readiness`
- BYO (Bring Your Own) support for network, firewall, and SSH key
- HA control plane with `for_each`-based node identity
- Zero-SSH design — readiness via HTTPS polling, no remote-exec
- Cross-variable guardrails via `check {}` blocks
- 23 unit tests with `mock_provider` (zero credentials, ~3s)
- Pre-commit hooks (fmt, validate, tflint, terraform-docs, conventional-commits)
