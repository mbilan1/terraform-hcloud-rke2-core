# ──────────────────────────────────────────────────────────────────────────────
# _readiness — Cluster Health Check & Kubeconfig Retrieval
#
# COMPROMISE: Uses SSH (remote-exec) for kubeconfig retrieval.
# Why: RKE2 writes the kubeconfig to a local file on the initial master.
#      There is no API endpoint to retrieve it without prior authentication.
#      SSH is the only reliable method to fetch it post-bootstrap.
# TODO: Replace with Packer-based approach when pre-baked images are ready.
#       The image could embed a mechanism to push kubeconfig to a secure
#       endpoint (e.g., Hetzner metadata or a temporary HTTPS callback).
#
# DECISION: terraform_data with provisioner instead of null_resource.
# Why: terraform_data is the modern replacement (OpenTofu 1.7+). It supports
#      triggers_replace for controlled re-execution and doesn't require the
#      hashicorp/null provider.
# ──────────────────────────────────────────────────────────────────────────────

# ─── Wait for API Server ─────────────────────────────────────────────────────

resource "terraform_data" "wait_for_api" {
  count = var.create ? 1 : 0

  # DECISION: Trigger on initial master IP to re-run if the master changes.
  # Why: If the initial master is replaced, we need to re-verify readiness
  #      and re-fetch the kubeconfig from the new master.
  triggers_replace = [var.initial_master_ipv4]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = var.initial_master_ipv4
      user        = "root"
      port        = var.ssh_port
      private_key = var.ssh_private_key
    }

    # DECISION: Poll for up to 10 minutes (60 attempts × 10s).
    # Why: RKE2 takes 3-6 minutes to bootstrap on a fresh node. The 10-minute
    #      window provides generous margin for slow network or server types.
    inline = [
      <<-EOT
        echo "Waiting for RKE2 API server to become ready..."
        for i in $(seq 1 60); do
          if /var/lib/rancher/rke2/bin/kubectl \
            --kubeconfig /etc/rancher/rke2/rke2.yaml \
            get nodes >/dev/null 2>&1; then
            echo "API server is ready after $((i * 10)) seconds"
            exit 0
          fi
          echo "Attempt $i/60: API server not ready, waiting 10s..."
          sleep 10
        done
        echo "ERROR: API server did not become ready within 10 minutes"
        exit 1
      EOT
    ]
  }
}

# ─── Fetch Kubeconfig ────────────────────────────────────────────────────────

# DECISION: Separate resource for kubeconfig fetch (not combined with readiness).
# Why: Separation allows re-fetching the kubeconfig independently via taint,
#      without re-running the full readiness check.
resource "terraform_data" "fetch_kubeconfig" {
  count = var.create ? 1 : 0

  triggers_replace = [var.initial_master_ipv4]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = var.initial_master_ipv4
      user        = "root"
      port        = var.ssh_port
      private_key = var.ssh_private_key
    }

    inline = [
      "cat /etc/rancher/rke2/rke2.yaml"
    ]
  }

  depends_on = [terraform_data.wait_for_api]
}
