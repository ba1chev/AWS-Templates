# EC2 module

Application tier: an EC2 Auto Scaling group running in private subnets.

## What it creates

- Launch template using the latest Amazon Linux 2023 AMI (or a given `ami_id`)
  - IMDSv2 required
  - Encrypted gp3 root volume
- IAM role and instance profile with `AmazonSSMManagedInstanceCore`, so instances are reachable through
  SSM Session Manager with no SSH keys or open port 22
- Auto Scaling group
  - Uses ELB health checks when attached to a target group
  - Rolls out a new launch template version with a rolling instance refresh
- Target tracking scaling policy on average CPU (50% by default)

## Usage

```hcl
module "app" {
  source = "../../modules/compute/ec2"

  name               = "dev-app"
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.app_sg.security_group_id]
  target_group_arns  = [module.alb.target_group_arn]

  instance_type = "t3.micro"
  min_size      = 1
  max_size      = 3

  user_data = <<-EOT
    #!/bin/bash
    dnf install -y nginx
    systemctl enable --now nginx
  EOT
}
```

Private subnets need outbound internet access (a NAT gateway) or VPC endpoints for SSM and package installs to work.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | — | Name prefix (1-32 chars) |
| `subnet_ids` | `list(string)` | — | Subnets to launch instances in |
| `security_group_ids` | `list(string)` | — | Security groups for the instances |
| `instance_type` | `string` | `"t3.micro"` | EC2 instance type |
| `ami_id` | `string` | `null` | AMI; latest Amazon Linux 2023 if null |
| `ami_ssm_parameter` | `string` | AL2023 x86_64 path | SSM parameter used when `ami_id` is null |
| `key_name` | `string` | `null` | EC2 key pair (usually not needed) |
| `user_data` | `string` | `null` | Plain-text user data script |
| `root_volume_size` | `number` | `20` | Root volume size in GiB |
| `root_volume_type` | `string` | `"gp3"` | Root volume type |
| `min_size` | `number` | `1` | Minimum instances |
| `max_size` | `number` | `2` | Maximum instances |
| `desired_capacity` | `number` | `null` | Initial instances; null starts at `min_size` |
| `target_group_arns` | `list(string)` | `[]` | Target groups to register in |
| `health_check_grace_period` | `number` | `300` | Seconds before health checks count |
| `cpu_target_value` | `number` | `50` | CPU % target; null disables auto scaling |
| `instance_refresh_min_healthy_percentage` | `number` | `50` | Healthy % kept during a refresh |
| `enable_detailed_monitoring` | `bool` | `false` | 1-minute CloudWatch metrics |
| `iam_policy_arns` | `list(string)` | `[]` | Extra policies for the instance role |
| `tags` | `map(string)` | `{}` | Tags for all resources, including the instances |

## Outputs

| Name | Description |
|------|-------------|
| `autoscaling_group_name` | ASG name |
| `autoscaling_group_arn` | ASG ARN |
| `launch_template_id` | Launch template ID |
| `ami_id` | AMI in use |
| `iam_role_name` | Instance role name |
| `iam_role_arn` | Instance role ARN |
| `instance_profile_arn` | Instance profile ARN |

## Tests

```bash
terraform init
terraform test
```
