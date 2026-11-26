# AWS-Templates

Reusable templates for AWS infrastructure.

## Terraform

| Path | Description |
|------|-------------|
| [`terraform/vpc_module`](terraform/vpc_module) | VPC with public/private subnets, IGW, NAT gateway(s), and route tables |
| [`terraform/security_group_module`](terraform/security_group_module) | Security group with ingress/egress rules as separate resources |

### Run the module tests

```bash
cd terraform/vpc_module   # or terraform/security_group_module
terraform init
terraform test
```

The tests use a mocked AWS provider, so they need no credentials and create nothing.

Requirements: Terraform >= 1.7 to run the tests (the modules themselves need >= 1.5), AWS provider >= 5.0.
