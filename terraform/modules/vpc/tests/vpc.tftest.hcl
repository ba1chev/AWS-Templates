# Run with: terraform init && terraform test
# Uses a mocked AWS provider - no credentials needed, nothing is created.
mock_provider "aws" {
  override_data {
    target = data.aws_availability_zones.available
    values = {
      names = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
    }
  }
}

variables {
  name = "test"
}

run "defaults" {
  command = apply

  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR should default to 10.0.0.0/16."
  }

  assert {
    condition     = aws_vpc.main.enable_dns_hostnames && aws_vpc.main.enable_dns_support
    error_message = "DNS support and hostnames should be enabled by default."
  }

  assert {
    condition     = length(aws_subnet.public) == 2 && length(aws_subnet.private) == 2
    error_message = "Expected 2 public and 2 private subnets by default."
  }

  assert {
    condition     = [for s in aws_subnet.public : s.availability_zone] == ["eu-central-1a", "eu-central-1b"]
    error_message = "Public subnets should be spread across the first two AZs."
  }

  assert {
    condition     = alltrue([for s in aws_subnet.public : !s.map_public_ip_on_launch])
    error_message = "Public subnets should not auto-assign public IPs by default."
  }

  assert {
    condition     = length(aws_internet_gateway.main) == 1
    error_message = "Expected an internet gateway when public subnets exist."
  }

  assert {
    condition     = length(aws_nat_gateway.main) == 1 && length(aws_eip.nat) == 1
    error_message = "Expected a single NAT gateway by default."
  }

  assert {
    condition     = length(aws_route.private_nat) == 2
    error_message = "Every private route table should get a default route via NAT."
  }

  assert {
    condition     = length(aws_default_security_group.default) == 1
    error_message = "Default security group should be managed (rules stripped) by default."
  }
}

run "nat_per_az" {
  command = apply

  variables {
    single_nat_gateway = false
  }

  assert {
    condition     = length(aws_nat_gateway.main) == 2
    error_message = "Expected one NAT gateway per public subnet."
  }

  assert {
    condition     = aws_route.private_nat[1].nat_gateway_id == aws_nat_gateway.main[1].id
    error_message = "Second private subnet should route through the second NAT gateway."
  }
}

run "no_nat" {
  command = apply

  variables {
    enable_nat_gateway = false
  }

  assert {
    condition     = length(aws_nat_gateway.main) == 0 && length(aws_eip.nat) == 0
    error_message = "No NAT gateway should be created when disabled."
  }

  assert {
    condition     = length(aws_route.private_nat) == 0
    error_message = "Private route tables should have no default route without NAT."
  }
}

run "private_only" {
  command = apply

  variables {
    public_subnet_cidrs  = []
    private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  }

  assert {
    condition     = length(aws_internet_gateway.main) == 0 && length(aws_nat_gateway.main) == 0
    error_message = "No IGW or NAT should exist without public subnets."
  }

  assert {
    condition     = length(aws_subnet.private) == 3 && output.azs == tolist(["eu-central-1a", "eu-central-1b", "eu-central-1c"])
    error_message = "Three private subnets should be spread across three AZs."
  }
}

run "invalid_cidr" {
  command = plan

  variables {
    vpc_cidr_block = "not-a-cidr"
  }

  expect_failures = [var.vpc_cidr_block]
}
