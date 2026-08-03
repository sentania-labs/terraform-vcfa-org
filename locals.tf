# Pass-through of the validated OIDC group -> role mapping. Kept as a local (and exposed via
# outputs.tf) rather than wired into a resource: the vmware/vcfa provider does not yet expose a
# resource for importing OIDC groups into an org, so this module can only guarantee the names are
# well-formed (lowercase) ahead of whatever process (manual, future resource) actually imports them.
#
# Grouped by name first (the trailing `...` puts every group sharing a name into one list)
# because a single AD group legitimately needs more than one VCFA role (e.g. an admins group
# needing both Organization Administrator and Service Broker Admin), which callers express by
# repeating the group name once per role. Building the map directly off `g.role` collides on
# that repeated key and fails with "Duplicate object key".
locals {
  oidc_group_role_map = var.oidc == null ? {} : {
    for name, groups in { for g in var.oidc.groups : g.name => g... } :
    name => [for g in groups : g.role]
  }
}
