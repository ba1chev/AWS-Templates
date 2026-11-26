variable "name" {
  type        = string
  description = "Name of the load balancer. The target group is named \"<name>-tg\"."

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-]{0,27}[a-zA-Z0-9])?$", var.name))
    error_message = "name must be 1-29 characters, only letters, digits and hyphens, and must not start or end with a hyphen."
  }
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC the target group belongs to."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets for the load balancer (public subnets for an internet-facing ALB). At least two, in different AZs."

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "An Application Load Balancer needs at least two subnets in different AZs."
  }
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security groups attached to the load balancer."
}

variable "internal" {
  type        = bool
  default     = false
  description = "Create an internal load balancer instead of an internet-facing one."
}

variable "enable_deletion_protection" {
  type        = bool
  default     = false
  description = "Prevent the load balancer from being deleted. Recommended for prod."
}

variable "idle_timeout" {
  type        = number
  default     = 60
  description = "Idle connection timeout in seconds."
}

variable "certificate_arn" {
  type        = string
  default     = null
  description = "ACM certificate ARN. If set, an HTTPS listener is created and HTTP redirects to HTTPS. If null, HTTP forwards straight to the target group."
}

variable "ssl_policy" {
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  description = "SSL policy for the HTTPS listener."
}

variable "target_port" {
  type        = number
  default     = 80
  description = "Port the targets (application instances) listen on."
}

variable "target_protocol" {
  type        = string
  default     = "HTTP"
  description = "Protocol used between the load balancer and the targets (HTTP or HTTPS)."

  validation {
    condition     = contains(["HTTP", "HTTPS"], var.target_protocol)
    error_message = "target_protocol must be HTTP or HTTPS."
  }
}

variable "target_type" {
  type        = string
  default     = "instance"
  description = "Target type: \"instance\" for EC2/Auto Scaling, \"ip\" for ECS Fargate or IP targets."

  validation {
    condition     = contains(["instance", "ip"], var.target_type)
    error_message = "target_type must be instance or ip."
  }
}

variable "deregistration_delay" {
  type        = number
  default     = 30
  description = "Seconds to wait for in-flight requests before deregistering a target."
}

variable "health_check" {
  type = object({
    path                = optional(string, "/")
    matcher             = optional(string, "200")
    interval            = optional(number, 30)
    timeout             = optional(number, 5)
    healthy_threshold   = optional(number, 3)
    unhealthy_threshold = optional(number, 3)
  })
  default     = {}
  description = "Target group health check settings. Any field left out uses its default."
}

variable "access_logs_bucket" {
  type        = string
  default     = null
  description = "S3 bucket for access logs. Logging is disabled when null."
}

variable "access_logs_prefix" {
  type        = string
  default     = null
  description = "Key prefix for access logs in the S3 bucket."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to every resource created by this module."
}
