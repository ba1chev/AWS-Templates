# Security group module

Security group whose rules are managed as separate `aws_vpc_security_group_ingress_rule` /
`aws_vpc_security_group_egress_rule` resources. This is the current AWS provider recommendation
over inline `ingress`/`egress` blocks: each rule can be added or removed without touching the others,
and each rule supports its own description and tags.

## What it creates

- Security group (`create_before_destroy`, named with a unique suffix by default)
- One ingress rule per entry in `ingress_rules`
- Allow-all egress for IPv4 + IPv6 (AWS's default behaviour); can be turned off
- One egress rule per entry in `egress_rules`

## Usage

```hcl
module "web_sg" {
  source = "../security_group_module"

  name        = "web"
  description = "Web servers"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    https = { description = "HTTPS from anywhere", from_port = 443, cidr_ipv4 = "0.0.0.0/0" }
    ssh   = { description = "SSH from office", from_port = 22, cidr_ipv4 = "203.0.113.10/32" }
    app   = { description = "App from ALB", from_port = 8080, referenced_security_group_id = module.alb_sg.security_group_id }
    self  = { description = "All traffic within the group", ip_protocol = "-1", self = true }
  }
}
```

## Rule format

Rules are a **map** keyed by a stable name, so reordering or removing one rule doesn't recreate the others.

| Field | Default | Notes |
|-------|---------|-------|
| `description` | `null` | Shown in the AWS console |
| `ip_protocol` | `"tcp"` | `tcp`, `udp`, `icmp`, or `"-1"` for all traffic |
| `from_port` | — | Required unless `ip_protocol = "-1"` |
| `to_port` | `from_port` | Set it for a port range |
| `cidr_ipv4` | | **Exactly one** of these five sources |
| `cidr_ipv6` | | |
| `prefix_list_id` | | |
| `referenced_security_group_id` | | |
| `self` | `false` | `true` references the group itself |

Invalid rules (no source, multiple sources, or ports set on an all-traffic rule) fail at `plan` time.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | — | Security group name (or prefix) |
| `use_name_prefix` | `bool` | `true` | Use `name` as a prefix with a unique suffix |
| `description` | `string` | `"Managed by Terraform"` | Description; changing it forces a replacement |
| `vpc_id` | `string` | — | VPC ID |
| `ingress_rules` | `map(object)` | `{}` | Inbound rules |
| `egress_rules` | `map(object)` | `{}` | Outbound rules |
| `allow_all_egress` | `bool` | `true` | Add allow-all IPv4/IPv6 egress |
| `tags` | `map(string)` | `{}` | Tags for the group and its rules |

## Outputs

| Name | Description |
|------|-------------|
| `security_group_id` | Security group ID |
| `security_group_arn` | Security group ARN |
| `security_group_name` | Actual name, including the generated suffix |
| `ingress_rule_ids` | Map of rule key to ingress rule ID |
| `egress_rule_ids` | Map of rule key to egress rule ID |

## Tests

```bash
terraform init
terraform test
```
