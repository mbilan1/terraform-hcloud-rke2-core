# _readiness

Cluster health check via HTTPS polling against the Kubernetes API server.

Uses `local-exec` with `curl` to poll `https://{ip}:6443/readyz` — no SSH
required. Part of the zero-SSH design philosophy.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
