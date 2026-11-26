# VPC module

Standard VPC with public and private subnets spread across availability zones.

## What it creates

- VPC with DNS support and DNS hostnames enabled
- Public subnets with a shared route table and a default route through an Internet Gateway
- Private subnets, each with its own route table and a default route through a NAT gateway (optional)
- NAT gateway(s) with Elastic IPs: a single shared one (default, cheaper) or one per AZ (highly available)
- The VPC's default security group with all rules removed, so nothing relies on it (CIS / Security Hub EC2.2)

## Usage

```hcl
module "vpc" {
  source = "../vpc_module"

  name           = "dev"
  vpc_cidr_block = "10.0.0.0/16"

  public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true # set to false in prod for one NAT per AZ

  tags = {
    Environment = "dev"
  }
}
```

Subnet `i` is placed in `azs[i]`. If `azs` is empty, the first N available AZs in the region are used.

> **Cost:** each NAT gateway is billed per hour plus per GB processed. Set `enable_nat_gateway = false`
> when you're just experimenting and the private subnets don't need internet access.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | — | Name prefix for all resources |
| `vpc_cidr_block` | `string` | `"10.0.0.0/16"` | VPC CIDR block |
| `azs` | `list(string)` | `[]` | AZs to use; auto-detected if empty |
| `public_subnet_cidrs` | `list(string)` | `["10.0.0.0/24", "10.0.1.0/24"]` | Public subnet CIDRs |
| `private_subnet_cidrs` | `list(string)` | `["10.0.10.0/24", "10.0.11.0/24"]` | Private subnet CIDRs |
| `enable_dns_support` | `bool` | `true` | Enable DNS resolution |
| `enable_dns_hostnames` | `bool` | `true` | Enable DNS hostnames |
| `map_public_ip_on_launch` | `bool` | `false` | Auto-assign public IPs in public subnets |
| `enable_nat_gateway` | `bool` | `true` | Create NAT gateway(s) for private subnets |
| `single_nat_gateway` | `bool` | `true` | One shared NAT (`true`) or one per AZ (`false`) |
| `manage_default_security_group` | `bool` | `true` | Strip all rules from the default SG |
| `tags` | `map(string)` | `{}` | Tags for all resources |
| `public_subnet_tags` | `map(string)` | `{}` | Extra tags for public subnets |
| `private_subnet_tags` | `map(string)` | `{}` | Extra tags for private subnets |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | VPC ID |
| `vpc_arn` | VPC ARN |
| `vpc_cidr_block` | VPC CIDR block |
| `azs` | AZs used by the subnets |
| `public_subnet_ids` | Public subnet IDs |
| `private_subnet_ids` | Private subnet IDs |
| `internet_gateway_id` | Internet Gateway ID (`null` if there are no public subnets) |
| `nat_gateway_ids` | NAT gateway IDs |
| `nat_public_ips` | NAT gateway public IPs |
| `public_route_table_id` | Public route table ID |
| `private_route_table_ids` | Private route table IDs |
| `default_security_group_id` | Default security group ID |

## Tests

```bash
terraform init
terraform test
```

The tests use a mocked AWS provider, so they need no credentials and create nothing.
