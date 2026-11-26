variable "name" {
  type        = string
  description = "Name prefix for the Auto Scaling group, launch template and IAM role."

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,31}$", var.name))
    error_message = "name must be 1-32 characters, only letters, digits and hyphens, and must not start with a hyphen."
  }
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets to launch instances in (private subnets for the application tier)."
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security groups attached to the instances."
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type."
}

variable "ami_id" {
  type        = string
  default     = null
  description = "AMI to use. If null, the latest Amazon Linux 2023 AMI is looked up from ami_ssm_parameter."
}

variable "ami_ssm_parameter" {
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
  description = "Public SSM parameter holding the AMI ID, used when ami_id is null. Use the arm64 path for Graviton instance types."
}

variable "key_name" {
  type        = string
  default     = null
  description = "EC2 key pair name. Usually not needed, since instances are reachable through SSM Session Manager."
}

variable "user_data" {
  type        = string
  default     = null
  description = "Plain-text user data script (the module base64-encodes it)."
}

variable "root_volume_size" {
  type        = number
  default     = 20
  description = "Root EBS volume size in GiB."
}

variable "root_volume_type" {
  type        = string
  default     = "gp3"
  description = "Root EBS volume type."
}

variable "min_size" {
  type        = number
  default     = 1
  description = "Minimum number of instances."
}

variable "max_size" {
  type        = number
  default     = 2
  description = "Maximum number of instances."
}

variable "desired_capacity" {
  type        = number
  default     = null
  description = "Initial number of instances. Leave null to start at min_size and let the scaling policy manage it."
}

variable "target_group_arns" {
  type        = list(string)
  default     = []
  description = "Load balancer target groups to register instances in. When set, the ASG uses ELB health checks."
}

variable "health_check_grace_period" {
  type        = number
  default     = 300
  description = "Seconds after launch before health checks start counting."
}

variable "cpu_target_value" {
  type        = number
  default     = 50
  description = "Average CPU % the target tracking policy aims for. Set to null to disable auto scaling."
}

variable "instance_refresh_min_healthy_percentage" {
  type        = number
  default     = 50
  description = "Minimum % of healthy instances kept during a rolling instance refresh."
}

variable "enable_detailed_monitoring" {
  type        = bool
  default     = false
  description = "Enable 1-minute CloudWatch metrics (billed extra)."
}

variable "iam_policy_arns" {
  type        = list(string)
  default     = []
  description = "Extra IAM policy ARNs to attach to the instance role. AmazonSSMManagedInstanceCore is always attached."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to every resource created by this module, including the instances."
}
