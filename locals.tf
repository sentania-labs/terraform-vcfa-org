# Pass-through of the validated OIDC group -> role mapping. Kept as a local (and exposed via
# outputs.tf) rather than wired into a resource: the vmware/vcfa provider does not yet expose a
# resource for importing OIDC groups into an org, so this module can only guarantee the names are
# well-formed (lowercase) ahead of whatever process (manual, future resource) actually imports them.
locals {
  oidc_group_role_map = var.oidc == null ? {} : { for g in var.oidc.groups : g.name => g.role }
}
