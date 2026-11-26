# AWS-Templates

Reusable templates for the base infrastructure of a classic 3-tier architecture on AWS.

## Structure

```
terraform/
├── modules/        # Reusable building blocks
└── environments/   # Root configurations that compose the modules per environment
```

- **modules**: self-contained, tested modules. Each one is a single building block of the architecture.
- **environments**: ready-to-deploy configurations (e.g. `dev`, `prod`) that wire the modules together.

## Modules

| Module | Description |
|--------|-------------|
| [`vpc`](terraform/modules/vpc) | VPC with public/private subnets, IGW, NAT gateway(s), and route tables |
| [`security_group`](terraform/modules/security_group) | Security group with ingress/egress rules as separate resources |

## Running the module tests

```bash
cd terraform/modules/vpc   # or any other module
terraform init
terraform test
```

The tests use a mocked AWS provider, so they need no credentials and create nothing.

Requirements: Terraform >= 1.7 to run the tests (the modules themselves need >= 1.5), AWS provider >= 5.0.
