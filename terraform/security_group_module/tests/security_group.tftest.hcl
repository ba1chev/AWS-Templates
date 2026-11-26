# Run with: terraform init && terraform test
# Uses a mocked AWS provider - no credentials needed, nothing is created.
mock_provider "aws" {}

variables {
  name   = "test"
  vpc_id = "vpc-12345678"
}

run "defaults_allow_all_egress" {
  command = apply

  assert {
    condition     = aws_security_group.this.name_prefix == "test-" && aws_security_group.this.tags["Name"] == "test"
    error_message = "Should use name as prefix and tag Name by default."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.this) == 0
    error_message = "No ingress rules by default."
  }

  assert {
    condition     = toset(keys(aws_vpc_security_group_egress_rule.this)) == toset(["all_ipv4", "all_ipv6"])
    error_message = "Expected allow-all IPv4 and IPv6 egress by default."
  }
}

run "ingress_rules" {
  command = apply

  variables {
    ingress_rules = {
      https = { from_port = 443, cidr_ipv4 = "0.0.0.0/0" }
      range = { from_port = 8000, to_port = 8100, cidr_ipv6 = "::/0" }
      self  = { ip_protocol = "-1", self = true }
      peer  = { from_port = 5432, referenced_security_group_id = "sg-0123456789abcdef0" }
    }
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.this["https"].ip_protocol == "tcp" && aws_vpc_security_group_ingress_rule.this["https"].to_port == 443
    error_message = "ip_protocol should default to tcp and to_port to from_port."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.this["range"].from_port == 8000 && aws_vpc_security_group_ingress_rule.this["range"].to_port == 8100
    error_message = "Explicit port ranges should be kept."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.this["self"].referenced_security_group_id == aws_security_group.this.id
    error_message = "self = true should reference the group's own ID."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.this["self"].from_port == null
    error_message = "All-traffic rules should not set ports."
  }
}

run "locked_down_egress" {
  command = apply

  variables {
    allow_all_egress = false
    egress_rules = {
      https_out = { from_port = 443, cidr_ipv4 = "0.0.0.0/0" }
    }
  }

  assert {
    condition     = keys(aws_vpc_security_group_egress_rule.this) == ["https_out"]
    error_message = "Only the explicit egress rule should exist."
  }
}

run "fixed_name" {
  command = apply

  variables {
    use_name_prefix = false
  }

  assert {
    condition     = aws_security_group.this.name == "test"
    error_message = "use_name_prefix = false should set an exact name."
  }
}

run "rejects_multiple_sources" {
  command = plan

  variables {
    ingress_rules = {
      bad = { from_port = 22, cidr_ipv4 = "10.0.0.0/8", self = true }
    }
  }

  expect_failures = [var.ingress_rules]
}

run "rejects_missing_source" {
  command = plan

  variables {
    egress_rules = {
      bad = { from_port = 443 }
    }
  }

  expect_failures = [var.egress_rules]
}

run "rejects_ports_on_all_traffic" {
  command = plan

  variables {
    ingress_rules = {
      bad = { ip_protocol = "-1", from_port = 0, to_port = 65535, cidr_ipv4 = "10.0.0.0/8" }
    }
  }

  expect_failures = [var.ingress_rules]
}
