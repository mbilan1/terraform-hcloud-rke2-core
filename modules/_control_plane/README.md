# _control_plane

RKE2 control plane server instances with cloud-init bootstrap.

Creates an initial master (cluster bootstrap node) and joining nodes.
All nodes use `for_each` over a `map(object)` for stable identity —
removing a single node key only destroys that server.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
