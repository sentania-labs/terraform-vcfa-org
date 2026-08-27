mock_provider "vcfa" {}

variables {
  name               = "classification-test"
  display_name       = "Classification Test"
  oidc_client_secret = "unused-test-value"
}

run "vm_apps_classification" {
  command = plan

  variables {
    is_classic_tenant = true
  }

  assert {
    condition     = vcfa_org.this.is_classic_tenant == true
    error_message = "A VM Apps classification must reach vcfa_org as true."
  }
}

run "all_apps_classification" {
  command = plan

  variables {
    is_classic_tenant = false
  }

  assert {
    condition     = vcfa_org.this.is_classic_tenant == false
    error_message = "An All Apps classification must reach vcfa_org as false."
  }
}

run "compatibility_default" {
  command = plan

  assert {
    condition     = vcfa_org.this.is_classic_tenant == null
    error_message = "The compatibility default must leave is_classic_tenant unset."
  }
}
