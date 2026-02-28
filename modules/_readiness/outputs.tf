# ──────────────────────────────────────────────────────────────────────────────
# _readiness — Outputs
#
# DECISION: No kubeconfig output — kubeconfig retrieval is Rancher's job.
# Why: This module is pure L3 infrastructure. Kubeconfig is retrieved via the
#      terraform-hcloud-rancher management module, which has Kubernetes API
#      access post-bootstrap. This keeps the zero-SSH design clean.
# See: docs/ARCHITECTURE.md — Kubeconfig Strategy
# ──────────────────────────────────────────────────────────────────────────────

output "cluster_ready" {
  description = "Boolean indicating the cluster API server is reachable. Depends on the HTTPS readiness check completing."
  value       = var.create ? true : null

  depends_on = [terraform_data.wait_for_api]
}

output "api_ready_id" {
  description = "ID of the readiness check resource. Use as depends_on target."
  value       = try(terraform_data.wait_for_api["this"].id, null)
}
