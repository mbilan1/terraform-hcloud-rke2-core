# ──────────────────────────────────────────────────────────────────────────────
# _readiness — Outputs
#
# NOTE: The kubeconfig content cannot be captured from remote-exec output
#       in the current implementation. A future iteration should use a
#       file provisioner or external data source to retrieve it properly.
# TODO: Implement kubeconfig output via remote provider or local-exec + SSH.
# ──────────────────────────────────────────────────────────────────────────────

output "cluster_ready" {
  description = "Boolean indicating the cluster API server is responsive. Depends on the readiness check completing."
  value       = var.create ? true : null

  depends_on = [terraform_data.wait_for_api]
}

output "api_ready_id" {
  description = "ID of the readiness check resource. Use as depends_on target."
  value       = try(terraform_data.wait_for_api[0].id, null)
}
