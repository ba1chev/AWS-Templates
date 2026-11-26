# ALB module

Presentation tier: an Application Load Balancer with a target group for the application tier.

## What it creates

- Application Load Balancer (internet-facing by default) that drops invalid HTTP headers
- Target group with a configurable health check
- HTTP listener on port 80
- HTTPS listener on port 443 with a TLS 1.3 policy, only when `certificate_arn` is set

With a certificate, HTTP redirects to HTTPS (301). Without one, HTTP forwards straight to the
target group, which is handy for dev environments without a domain.

## Usage

```hcl
module "alb" {
  source = "../../modules/presentation/alb"

  name               = "dev-app"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.alb_sg.security_group_id]

  certificate_arn = null # set an ACM certificate ARN to enable HTTPS
  target_port     = 8080

  health_check = {
    path = "/health"
  }
}
```

Pass `module.alb.target_group_arn` to the EC2 module's `target_group_arns`.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | — | ALB name (1-29 chars); target group is `<name>-tg` |
| `vpc_id` | `string` | — | VPC ID |
| `subnet_ids` | `list(string)` | — | At least 2 subnets in different AZs |
| `security_group_ids` | `list(string)` | — | Security groups for the ALB |
| `internal` | `bool` | `false` | Internal instead of internet-facing |
| `enable_deletion_protection` | `bool` | `false` | Prevent deletion (recommended for prod) |
| `idle_timeout` | `number` | `60` | Idle timeout in seconds |
| `certificate_arn` | `string` | `null` | ACM certificate; enables HTTPS |
| `ssl_policy` | `string` | `"ELBSecurityPolicy-TLS13-1-2-2021-06"` | HTTPS listener SSL policy |
| `target_port` | `number` | `80` | Port the targets listen on |
| `target_protocol` | `string` | `"HTTP"` | `HTTP` or `HTTPS` |
| `target_type` | `string` | `"instance"` | `instance` (EC2) or `ip` (Fargate) |
| `deregistration_delay` | `number` | `30` | Seconds to drain targets |
| `health_check` | `object` | `{}` | `path`, `matcher`, `interval`, `timeout`, `healthy_threshold`, `unhealthy_threshold` |
| `access_logs_bucket` | `string` | `null` | S3 bucket for access logs |
| `access_logs_prefix` | `string` | `null` | S3 key prefix for access logs |
| `tags` | `map(string)` | `{}` | Tags for all resources |

## Outputs

| Name | Description |
|------|-------------|
| `lb_arn` | ALB ARN |
| `lb_dns_name` | ALB DNS name |
| `lb_zone_id` | ALB hosted zone ID (for Route 53 alias records) |
| `target_group_arn` | Target group ARN |
| `http_listener_arn` | HTTP listener ARN |
| `https_listener_arn` | HTTPS listener ARN (`null` without a certificate) |

## Tests

```bash
terraform init
terraform test
```
