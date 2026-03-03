# ──────────────────────────────────────────────────────────────────────────────
# Guardrail Tests — Cross-Variable Preflight Check Blocks
# ──────────────────────────────────────────────────────────────────────────────

mock_provider "hcloud" {
  mock_resource "hcloud_network" {
    defaults = {
      id = 12345
    }
  }
  mock_resource "hcloud_network_subnet" {
    defaults = {
      id = 12346
    }
  }
  mock_resource "hcloud_server" {
    defaults = {
      id           = 12349
      ipv4_address = "10.0.0.1"
    }
  }
  mock_resource "hcloud_server_network" {
    defaults = {
      id = 12350
      ip = "10.0.1.1"
    }
  }
}
mock_provider "random" {}

# ─── BYO network with custom subnet (should warn) ────────────────────────────

run "byo_network_with_custom_subnet_warns" {
  command = plan

  variables {
    cluster_name        = "test-cluster"
    existing_network_id = 12345
    subnet_address      = "10.99.0.0/24"
    delete_protection   = true
  }

  expect_failures = [
    check.byo_network_subnet_ignored,
  ]
}

# ─── BYO network with default subnet (no warning) ────────────────────────────

run "byo_network_with_default_subnet_ok" {
  command = plan

  variables {
    cluster_name        = "test-cluster"
    existing_network_id = 12345
    delete_protection   = true
  }

  expect_failures = []
}

# ─── Delete protection advisory ──────────────────────────────────────────────

run "delete_protection_off_advisory" {
  command = plan

  variables {
    cluster_name      = "test-cluster"
    delete_protection = false
  }

  expect_failures = [
    check.delete_protection_advisory,
  ]
}

run "delete_protection_on_no_advisory" {
  command = plan

  variables {
    cluster_name      = "test-cluster"
    delete_protection = true
  }

  expect_failures = []
}

# ─── Location / network zone match ───────────────────────────────────────────

run "location_zone_match_hel1_eu_central" {
  command = plan

  variables {
    cluster_name        = "test-cluster"
    hcloud_location     = "hel1"
    hcloud_network_zone = "eu-central"
    delete_protection   = true
  }

  expect_failures = []
}

run "location_zone_mismatch_warns" {
  command = plan

  variables {
    cluster_name        = "test-cluster"
    hcloud_location     = "hel1"
    hcloud_network_zone = "us-east"
    delete_protection   = true
  }

  expect_failures = [
    check.location_network_zone_match,
  ]
}
