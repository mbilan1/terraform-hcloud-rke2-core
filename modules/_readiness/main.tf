# ──────────────────────────────────────────────────────────────────────────────
# _readiness — Cluster Health Check via HTTPS
#
# DECISION: Zero-SSH readiness check — poll Kubernetes API via HTTPS.
# Why: The module follows a zero-SSH design philosophy. SSH-based provisioners
#      are fragile, require private key access, and break the immutable
#      infrastructure pattern. HTTPS polling against port 6443 is simpler,
#      more reliable, and doesn't require any credentials beyond network
#      access to the API server endpoint.
#
# DECISION: Kubeconfig is NOT retrieved by this module.
# Why: Kubeconfig retrieval is handled by the Rancher management module
#      (terraform-hcloud-rancher), which has Kubernetes API access after
#      bootstrap. This module's responsibility is limited to confirming
#      the API server is reachable — nothing more.
# See: docs/ARCHITECTURE.md — Kubeconfig Strategy
#
# DECISION: terraform_data with local-exec provisioner.
# Why: terraform_data is the modern replacement for null_resource (OpenTofu
#      1.7+). local-exec with curl avoids SSH entirely — the check runs
#      from the machine executing tofu, not from the target server.
# ──────────────────────────────────────────────────────────────────────────────

resource "terraform_data" "wait_for_api" {
  for_each = var.create ? { this = true } : {}

  # DECISION: Trigger on initial master IP to re-run if the master changes.
  # Why: If the initial master is replaced, we need to re-verify that the
  #      new API server is reachable before downstream consumers proceed.
  triggers_replace = [var.initial_master_ipv4]

  provisioner "local-exec" {
    # DECISION: Poll for up to 10 minutes (60 attempts × 10s).
    # Why: RKE2 takes 3-6 minutes to bootstrap on a fresh node. The 10-minute
    #      window provides generous margin for slow network or server types.
    #
    # NOTE: curl -k is used because the RKE2 API server uses a self-signed
    #       certificate at bootstrap. The purpose is reachability check,
    #       not certificate validation.
    command = <<-EOT
      echo "Waiting for RKE2 API server at ${var.initial_master_ipv4}:6443..."
      for i in $(seq 1 60); do
        if curl -sk --connect-timeout 5 \
          "https://${var.initial_master_ipv4}:6443/readyz" \
          -o /dev/null -w "%%{http_code}" 2>/dev/null | grep -qE "^(200|401|403)$"; then
          echo "API server is reachable after $((i * 10)) seconds"
          exit 0
        fi
        echo "Attempt $i/60: API server not reachable, waiting 10s..."
        sleep 10
      done
      echo "ERROR: API server at ${var.initial_master_ipv4}:6443 did not become reachable within 10 minutes"
      exit 1
    EOT
  }
}
