# ──────────────────────────────────────────────────────────────────────────────
# Variable Validation Tests
#
# DECISION: Tests use mock_provider — zero cloud credentials, ~3s, $0.
# Why: Variable validation is pure logic. No infrastructure needed.
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
  mock_resource "hcloud_ssh_key" {
    defaults = {
      id = 12347
    }
  }
  mock_resource "hcloud_firewall" {
    defaults = {
      id = 12348
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
mock_provider "tls" {}
mock_provider "random" {}

# ─── Positive: Valid cluster names ────────────────────────────────────────────

run "valid_cluster_name_short" {
  command = plan

  variables {
    cluster_name      = "dev"
    delete_protection = true
  }

  expect_failures = []
}

run "valid_cluster_name_with_hyphens" {
  command = plan

  variables {
    cluster_name      = "my-production-cluster-01"
    delete_protection = true
  }

  expect_failures = []
}

# ─── Negative: Invalid cluster names ─────────────────────────────────────────

run "invalid_cluster_name_uppercase" {
  command = plan

  variables {
    cluster_name      = "MyCluster"
    delete_protection = true
  }

  expect_failures = [
    var.cluster_name,
  ]
}

run "invalid_cluster_name_starts_with_digit" {
  command = plan

  variables {
    cluster_name      = "1cluster"
    delete_protection = true
  }

  expect_failures = [
    var.cluster_name,
  ]
}

run "invalid_cluster_name_too_short" {
  command = plan

  variables {
    cluster_name      = "ab"
    delete_protection = true
  }

  expect_failures = [
    var.cluster_name,
  ]
}

run "invalid_cluster_name_ends_with_hyphen" {
  command = plan

  variables {
    cluster_name      = "my-cluster-"
    delete_protection = true
  }

  expect_failures = [
    var.cluster_name,
  ]
}

# ─── Location validation ─────────────────────────────────────────────────────

run "valid_hcloud_location_nbg1" {
  command = plan

  variables {
    cluster_name      = "test-cluster"
    hcloud_location   = "nbg1"
    delete_protection = true
  }

  expect_failures = []
}

run "invalid_hcloud_location" {
  command = plan

  variables {
    cluster_name      = "test-cluster"
    hcloud_location   = "invalid-dc"
    delete_protection = true
  }

  expect_failures = [
    var.hcloud_location,
  ]
}

# ─── SSH port validation ─────────────────────────────────────────────────────

run "valid_ssh_port_custom" {
  command = plan

  variables {
    cluster_name      = "test-cluster"
    ssh_port          = 2222
    delete_protection = true
  }

  expect_failures = []
}

run "invalid_ssh_port_zero" {
  command = plan

  variables {
    cluster_name      = "test-cluster"
    ssh_port          = 0
    delete_protection = true
  }

  expect_failures = [
    var.ssh_port,
  ]
}

run "invalid_ssh_port_too_high" {
  command = plan

  variables {
    cluster_name      = "test-cluster"
    ssh_port          = 70000
    delete_protection = true
  }

  expect_failures = [
    var.ssh_port,
  ]
}

# ─── Control plane count validation ──────────────────────────────────────────

run "valid_single_control_plane" {
  command = plan

  variables {
    cluster_name      = "test-cluster"
    delete_protection = true
    control_plane_nodes = {
      "cp-0" = {}
    }
  }

  expect_failures = []
}

run "valid_ha_control_plane" {
  command = plan

  variables {
    cluster_name      = "test-cluster"
    delete_protection = true
    control_plane_nodes = {
      "cp-0" = {}
      "cp-1" = {}
      "cp-2" = {}
    }
  }

  expect_failures = []
}

run "invalid_two_control_plane_nodes" {
  command = plan

  variables {
    cluster_name      = "test-cluster"
    delete_protection = true
    control_plane_nodes = {
      "cp-0" = {}
      "cp-1" = {}
    }
  }

  expect_failures = [
    var.control_plane_nodes,
  ]
}

# ─── Network zone validation ─────────────────────────────────────────────────

run "valid_hcloud_network_zone" {
  command = plan

  variables {
    cluster_name        = "test-cluster"
    hcloud_network_zone = "eu-central"
    delete_protection   = true
  }

  expect_failures = []
}

run "invalid_hcloud_network_zone" {
  command = plan

  variables {
    cluster_name        = "test-cluster"
    hcloud_network_zone = "invalid-zone"
    delete_protection   = true
  }

  expect_failures = [
    var.hcloud_network_zone,
  ]
}
