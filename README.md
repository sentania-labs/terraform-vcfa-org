# terraform-vcfa-org

Terraform module for the whole VCFA org product as a single unit: `vcfa_org`, `vcfa_org_settings`,
an optional local admin user (`vcfa_org_local_user`), and optional OIDC federation to vIDB
(`vcfa_org_oidc`).

OIDC lives inside this module on purpose, it is not a separate module. An org without its
federation wired up is not a usable org for anyone logging in through AD, so this module treats
getting OIDC right as part of what "creating an org" means.

## Why this module exists

Three orgs in this environment were hand-configured with OIDC, and every one of them drifted from
the correct shape at least once. The failure mode is silent: login still appears to work for some
users, so a misconfigured org can sit broken for a while before anyone notices group-based access
isn't working. This module hard-codes the fields that must never vary:

- **`scopes` must include `group`.** Without it, the token carries no group claims at all, so
  AD-group login can never work no matter how the groups are imported. Default is
  `["openid", "profile", "email", "group"]`.
- **Subject claim is always `preferred_username`.** Never `sub` (an opaque IdP UUID that can't be
  matched to a username) and never `acct` (hits a known vIDB double-UPN bug). This is not
  configurable through the module, it's fixed in `main.tf`.
- **Groups claim is always `group_names`.** Also fixed, not configurable.
- **Group names must be lowercase.** VCFA's group-import login match is case-sensitive against the
  AD group name. `labAdmins` vs `labadmins` doesn't error, it just silently locks out every member
  of that group. `var.oidc.groups[].name` has a validation block that rejects anything with an
  uppercase character.
- **`client_secret` is never defaulted.** It's a required, `sensitive = true` input
  (`var.oidc_client_secret`) with no default value anywhere in this module. It isn't recoverable
  from VCFA once set (it lives in vIDB / the Ops locker), so nothing here should ever ship a
  placeholder value that looks plausible.

## Known limitation: OIDC group import isn't a resource yet

The `vmware/vcfa` Terraform provider (checked against v1.2.0 schema) has no resource for importing
an OIDC group into an org and mapping it to a role, that step is still done by hand in the tenant
UI (or a tenant-scoped API call). This module still accepts and validates `var.oidc.groups` (lowercase
enforced) and surfaces the mapping via `output.oidc_group_role_map`, so the intended mapping is
recorded and checked even though this module can't create the import itself yet.

A group can need more than one role (e.g. an admins group needing both Organization Administrator
and Service Broker Admin). Express that by repeating the group name once per role; the output
groups them, so `oidc_group_role_map` is `map(list(string))`, one entry per distinct group name.

## Example

See `examples/` for a runnable example. In short:

```hcl
module "org" {
  source = "sentania-labs/org/vcfa"

  name         = "vcf-lab-vm-apps"
  display_name = "VM Apps"

  oidc = {
    client_id          = "26e6f555-7de3-456f-a23c-143a16fe6bb3"
    wellknown_endpoint = "https://vcf-lab-idb.int.sentania.net/acs/t/CUSTOMER/.well-known/openid-configuration"
    groups = [
      { name = "labadmins", role = "Organization Administrator" },
      { name = "labadmins", role = "Service Broker Admin" },
    ]
  }
  oidc_client_secret = var.oidc_client_secret # from TF_VAR_, never checked in
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.14.0 |
| <a name="requirement_vcfa"></a> [vcfa](#requirement\_vcfa) | >= 1.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_vcfa"></a> [vcfa](#provider\_vcfa) | >= 1.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [vcfa_org.this](https://registry.terraform.io/providers/vmware/vcfa/latest/docs/resources/org) | resource |
| [vcfa_org_local_user.admin](https://registry.terraform.io/providers/vmware/vcfa/latest/docs/resources/org_local_user) | resource |
| [vcfa_org_oidc.this](https://registry.terraform.io/providers/vmware/vcfa/latest/docs/resources/org_oidc) | resource |
| [vcfa_org_settings.this](https://registry.terraform.io/providers/vmware/vcfa/latest/docs/resources/org_settings) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_description"></a> [description](#input\_description) | Description for the organization. | `string` | `""` | no |
| <a name="input_display_name"></a> [display\_name](#input\_display\_name) | Human-friendly display name of the organization shown in the VCFA UI. | `string` | n/a | yes |
| <a name="input_is_enabled"></a> [is\_enabled](#input\_is\_enabled) | Whether the organization is enabled. Disabled orgs block all tenant login, including OIDC. | `bool` | `true` | no |
| <a name="input_local_admin"></a> [local\_admin](#input\_local\_admin) | Local (non-federated) admin user to create in the org, e.g. a break-glass account. Set to null to skip creating one. The account's password is supplied separately via var.local\_admin\_password. | <pre>object({<br/>    username = string<br/>    role_ids = set(string)<br/>  })</pre> | `null` | no |
| <a name="input_local_admin_password"></a> [local\_admin\_password](#input\_local\_admin\_password) | Password for the local admin user described in var.local\_admin. Required whenever var.local\_admin is set. No default: passwords are never shipped with a placeholder value, supply via TF\_VAR\_local\_admin\_password or an equivalent secret-injection mechanism, never in a checked-in tfvars file. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Machine name of the VCFA organization (immutable after creation). | `string` | n/a | yes |
| <a name="input_oidc"></a> [oidc](#input\_oidc) | OIDC federation to vIDB, the golden pattern this module exists to enforce. Set to null<br/>to leave the org unfederated (local users only). The subject claim (preferred\_username)<br/>and groups claim (group\_names) are NOT configurable here: they are hard-coded in this<br/>module because getting either wrong silently breaks login (subject=sub compares against<br/>an opaque IdP UUID instead of a username; subject=acct hits a known vIDB double-UPN bug).<br/><br/>`groups` records the AD group -> VCFA role mapping this org expects to import. The<br/>vmware/vcfa provider (as of v1.2.0) has no resource to create that import itself, so this<br/>module validates and exposes it (see output.oidc\_group\_role\_map) for manual reconciliation<br/>or a future resource, rather than silently dropping it. | <pre>object({<br/>    client_id              = string<br/>    wellknown_endpoint     = string<br/>    scopes                 = optional(set(string), ["openid", "profile", "email", "group"])<br/>    ui_button_label        = optional(string, "VCF SSO")<br/>    max_clock_skew_seconds = optional(number, 60)<br/>    prefer_id_token        = optional(bool, false)<br/>    groups = optional(list(object({<br/>      name = string<br/>      role = string<br/>    })), [])<br/>  })</pre> | `null` | no |
| <a name="input_oidc_client_secret"></a> [oidc\_client\_secret](#input\_oidc\_client\_secret) | Client secret for the OIDC registration described in var.oidc. Required whenever var.oidc is set (pass a placeholder value via TF\_VAR when oidc is null; the variable itself is always declared required). No default: this secret is not recoverable from VCFA once set, it lives in vIDB / the Ops locker, and secrets are never given a default value here. Supply via TF\_VAR\_oidc\_client\_secret or an equivalent secret-injection mechanism, never in a checked-in tfvars file. | `string` | n/a | yes |
| <a name="input_org_settings"></a> [org\_settings](#input\_org\_settings) | Org-wide content library settings. Every org gets a vcfa\_org\_settings resource; this is not optional in the module (it always follows org creation), only its values are tunable. Defaults are the conservative choice: no publish/subscribe federation, quarantine on. | <pre>object({<br/>    can_create_subscribed_libraries        = optional(bool, false)<br/>    can_subscribe_to_third_party_libraries = optional(bool, false)<br/>    quarantine_content_library_items       = optional(bool, true)<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_display_name"></a> [display\_name](#output\_display\_name) | Display name of the organization. |
| <a name="output_id"></a> [id](#output\_id) | URN of the created organization. Consumed by downstream modules (e.g. org-networking) as org\_id. |
| <a name="output_name"></a> [name](#output\_name) | Machine name of the organization. |
| <a name="output_oidc_group_role_map"></a> [oidc\_group\_role\_map](#output\_oidc\_group\_role\_map) | Validated (lowercase-checked) AD group name -> list of VCFA roles this org expects to import, from var.oidc.groups. A group name can carry more than one role (callers repeat the group name once per role), so each value is a list, not a single role string. Not wired to a resource: the vmware/vcfa provider has no group-import resource today. Empty map when var.oidc is not set. |
| <a name="output_oidc_redirect_uri"></a> [oidc\_redirect\_uri](#output\_oidc\_redirect\_uri) | Redirect URI VCFA generates for the OIDC client, computed once federation is created. Register this on the vIDB-side OIDC client. Null when var.oidc is not set. |
<!-- END_TF_DOCS -->
