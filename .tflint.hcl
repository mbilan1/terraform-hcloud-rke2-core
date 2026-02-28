# DECISION: TFLint configuration for Hetzner Cloud module.
# Why: Static analysis catches errors that tofu validate misses — unused
#      variables, deprecated syntax, naming conventions, etc.
# See: https://github.com/terraform-linters/tflint

config {
  # DECISION: Module inspection enabled for deep analysis.
  # Why: Catches issues inside child modules, not just the root.
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  version = "0.10.0"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"

  preset = "recommended"
}
