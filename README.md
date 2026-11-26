# AWS-Templates

Reusable templates for the base infrastructure of a classic 3-tier architecture on AWS.

## Structure

```
terraform/
├── modules/                  # Reusable building blocks, grouped by tier
│   ├── networking/<module>
│   ├── presentation/<module>
│   ├── compute/<module>
│   └── data/<module>
└── environments/             # Root configurations that compose the modules per environment
    ├── dev/
    ├── staging/
    └── prod/
```

- **modules**: self-contained, tested modules, grouped by tier. Each tier can have several
  implementations (e.g. `compute/ec2`, and later `compute/ecs`).
- **environments**: ready-to-deploy configurations that wire the modules together for each environment.

```
Internet -> presentation (public subnets) -> compute (private subnets) -> data (private subnets)
```

## Modules

| Tier | Module | Description |
|------|--------|-------------|
| Networking | [`networking/vpc`](terraform/modules/networking/vpc) | VPC with public/private subnets, IGW, NAT gateway(s), and route tables |
| Networking | [`networking/security_group`](terraform/modules/networking/security_group) | Security group with ingress/egress rules as separate resources |
| Presentation | [`presentation/alb`](terraform/modules/presentation/alb) | Application Load Balancer with target group and HTTP/HTTPS listeners |
| Compute | [`compute/ec2`](terraform/modules/compute/ec2) | EC2 Auto Scaling group with launch template, SSM access, and CPU scaling |
| Data | [`data/rds`](terraform/modules/data/rds) | RDS (PostgreSQL/MySQL) with encryption, backups, and Secrets Manager password |

## Running the module tests

```bash
cd terraform/modules/networking/vpc   # or any other module
terraform init
terraform test
```

The tests use a mocked AWS provider, so they need no credentials and create nothing.

Requirements: Terraform >= 1.7 to run the tests (the modules themselves need >= 1.5), AWS provider >= 5.0.
