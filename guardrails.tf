# ──────────────────────────────────────────────────────────────────────────────
# GUARDRAILS — Cross-variable preflight checks
#
# DECISION: All check blocks in root guardrails.tf, not in child modules.
# Why: check blocks are OpenTofu's native preflight validation mechanism.
#      Centralizing them gives a single file to audit for business rules.
#      They produce warnings (not errors) so apply isn't blocked, but
#      operators are alerted to risky configurations.
#
# DECISION: Cross-variable validation complements check blocks.
# Why: variable-level validation can only reference its own variable.
#      check blocks can reference multiple variables and locals, enabling
#      cross-cutting business rules like "BYO network requires no subnet config".
# ──────────────────────────────────────────────────────────────────────────────

# ─── Network Consistency ──────────────────────────────────────────────────────

check "byo_network_subnet_ignored" {
  # NOTE: When using BYO network, subnet_address and hcloud_network_cidr have no
  #       effect. Warn the user if they set non-default values alongside
  #       existing_network_id.
  assert {
    condition = (
      var.existing_network_id == null ||
      (var.hcloud_network_cidr == "10.0.0.0/16" && var.subnet_address == "10.0.1.0/24")
    )
    error_message = "WARNING: existing_network_id is set but hcloud_network_cidr or subnet_address are also customized. These will be ignored when using a BYO network."
  }
}

# ─── Location / Network Zone Consistency ──────────────────────────────────────

check "location_network_zone_match" {
  # NOTE: check blocks produce warnings, not errors — they never block apply.
  #       The || true was dead code making this check always pass. Removed.
  #       Unknown locations will now trigger the warning, which is the correct
  #       behavior — it alerts operators to verify compatibility.
  assert {
    # NOTE: sin (Singapore) mapped to ap-southeast — added 2026-03-01.
    #       Verified live via https://api.hetzner.cloud/v1/locations
    condition = (
      (contains(["nbg1", "fsn1", "hel1"], var.hcloud_location) && var.hcloud_network_zone == "eu-central") ||
      (contains(["ash"], var.hcloud_location) && var.hcloud_network_zone == "us-east") ||
      (contains(["hil"], var.hcloud_location) && var.hcloud_network_zone == "us-west") ||
      (contains(["sin"], var.hcloud_location) && var.hcloud_network_zone == "ap-southeast")
    )
    error_message = "WARNING: hcloud_location '${var.hcloud_location}' may not match hcloud_network_zone '${var.hcloud_network_zone}'. Verify they are in the same Hetzner region."
  }
}

# ─── Etcd Quorum ──────────────────────────────────────────────────────────────

# NOTE: This supplements the variable-level validation in variables.tf.
# The variable validation blocks the hard error (count == 2).
# This check provides a softer warning for other risky configurations.
check "control_plane_quorum_warning" {
  assert {
    condition = (
      length(var.control_plane_nodes) == 1 ||
      length(var.control_plane_nodes) >= 3
    )
    error_message = "WARNING: Control plane count is ${length(var.control_plane_nodes)}. For HA, use 3 or 5 nodes. Single node is fine for dev."
  }
}

# ─── API Access vs Executor Reachability ──────────────────────────────────────────

check "restricted_api_cidrs_advisory" {
  # NOTE: The _readiness local-exec curl runs on the machine executing
  #       `tofu apply` — NOT on the server. If k8s_api_allowed_cidrs restricts
  #       access to 6443, the readiness check silently hangs until timeout.
  #       Solutions: run tofu from within the allowed CIDR range (VPN/bastion),
  #       or use BYO firewall (existing_firewall_ids) that allows your runner.
  assert {
    condition = (
      !var.create ||
      contains(var.k8s_api_allowed_cidrs, "0.0.0.0/0") ||
      contains(var.k8s_api_allowed_cidrs, "::/0")
    )
    error_message = "ADVISORY: k8s_api_allowed_cidrs is restricted to ${jsonencode(var.k8s_api_allowed_cidrs)}. The local-exec readiness check runs from the tofu executor — it must be within this CIDR to reach port 6443. Use a VPN (e.g. Tailscale) or run from a host inside the allowed range."
  }
}

check "api_cidr_delete_protection_deadlock" {
  # DECISION: Hard DANGER (not just advisory) for this combination.
  # Why: This combination creates a two-way deadlock:
  #   1. apply hangs: local-exec curl can't reach 6443 → readiness never passes
  #   2. destroy fails: resources are delete-protected → manual unprotect via API needed
  # The only escape is manual Hetzner API calls to remove protection before cleanup.
  # See: docs/ARCHITECTURE.md — Operational Risks
  assert {
    condition = !(
      var.create &&
      var.delete_protection &&
      !contains(var.k8s_api_allowed_cidrs, "0.0.0.0/0") &&
      !contains(var.k8s_api_allowed_cidrs, "::/0")
    )
    error_message = "DANGER: delete_protection=true + restricted k8s_api_allowed_cidrs is a deadlock: apply will hang (readiness check cannot reach 6443 from the executor), and destroy will also fail because resources are delete-protected. Run tofu from within the allowed CIDR (e.g. via Tailscale) or use BYO firewall."
  }
}

# ─── Deletion Protection Consistency ──────────────────────────────────────────

check "delete_protection_advisory" {
  assert {
    condition     = var.delete_protection || !var.create
    error_message = "ADVISORY: delete_protection is false. All resources can be destroyed without protection. Consider enabling it for production clusters."
  }
}
