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
    condition = (
      (contains(["nbg1", "fsn1", "hel1"], var.hcloud_location) && var.hcloud_network_zone == "eu-central") ||
      (contains(["ash"], var.hcloud_location) && var.hcloud_network_zone == "us-east") ||
      (contains(["hil"], var.hcloud_location) && var.hcloud_network_zone == "us-west")
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

# ─── BYO SSH Key + Readiness ──────────────────────────────────────────────────

check "byo_ssh_key_readiness" {
  # NOTE: Readiness uses HTTPS polling — no SSH private key needed.
  #       This check is informational only: with BYO SSH key, the module
  #       won't output a private key, so operators need their own key for
  #       any manual SSH access (debugging, maintenance).
  assert {
    condition     = var.ssh_public_key == "" || !var.create
    error_message = "ADVISORY: Using a BYO SSH key (ssh_public_key is set). The module won't output a private key. Ensure you have the corresponding private key for manual SSH access if needed."
  }
}

# ─── Deletion Protection Consistency ──────────────────────────────────────────

check "delete_protection_advisory" {
  assert {
    condition     = var.delete_protection || !var.create
    error_message = "ADVISORY: delete_protection is false. All resources can be destroyed without protection. Consider enabling it for production clusters."
  }
}
