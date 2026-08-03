output "id" {
  description = "URN of the created organization. Consumed by downstream modules (e.g. org-networking) as org_id."
  value       = vcfa_org.this.id
}

output "name" {
  description = "Machine name of the organization."
  value       = vcfa_org.this.name
}

output "display_name" {
  description = "Display name of the organization."
  value       = vcfa_org.this.display_name
}

output "oidc_redirect_uri" {
  description = "Redirect URI VCFA generates for the OIDC client, computed once federation is created. Register this on the vIDB-side OIDC client. Null when var.oidc is not set."
  value       = try(vcfa_org_oidc.this[0].redirect_uri, null)
}

output "oidc_group_role_map" {
  description = "Validated (lowercase-checked) AD group name -> list of VCFA roles this org expects to import, from var.oidc.groups. A group name can carry more than one role (callers repeat the group name once per role), so each value is a list, not a single role string. Not wired to a resource: the vmware/vcfa provider has no group-import resource today. Empty map when var.oidc is not set."
  value       = local.oidc_group_role_map
}
