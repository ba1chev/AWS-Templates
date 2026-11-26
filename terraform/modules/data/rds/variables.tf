variable "name" {
  type        = string
  description = "Identifier of the DB instance, also used for the DB subnet group."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.name)) && !endswith(var.name, "-") && !strcontains(var.name, "--")
    error_message = "name must be 1-63 lowercase letters, digits or hyphens, start with a letter, and not end with a hyphen or contain two consecutive hyphens."
  }
}

variable "engine" {
  type        = string
  default     = "postgres"
  description = "Database engine: postgres or mysql."

  validation {
    condition     = contains(["postgres", "mysql"], var.engine)
    error_message = "engine must be postgres or mysql."
  }
}

variable "engine_version" {
  type        = string
  default     = null
  description = "Engine version, e.g. \"17\" or \"8.4\". If null, AWS picks the current default for the engine."
}

variable "instance_class" {
  type        = string
  default     = "db.t4g.micro"
  description = "DB instance class."
}

variable "allocated_storage" {
  type        = number
  default     = 20
  description = "Initial storage in GiB."
}

variable "max_allocated_storage" {
  type        = number
  default     = 100
  description = "Upper limit in GiB for storage autoscaling. Set to 0 to disable autoscaling."
}

variable "storage_type" {
  type        = string
  default     = "gp3"
  description = "Storage type."
}

variable "kms_key_id" {
  type        = string
  default     = null
  description = "KMS key ARN for storage encryption. If null, the AWS-managed RDS key is used. Storage is always encrypted."
}

variable "db_name" {
  type        = string
  default     = "app"
  description = "Name of the database created on the instance."
}

variable "username" {
  type        = string
  default     = "dbadmin"
  description = "Master username. The password is generated and stored in Secrets Manager by RDS."
}

variable "port" {
  type        = number
  default     = null
  description = "Database port. If null, the engine default is used (5432 for postgres, 3306 for mysql)."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets for the DB subnet group (private subnets). At least two, in different AZs."

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "A DB subnet group needs at least two subnets in different AZs."
  }
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security groups attached to the DB instance."
}

variable "multi_az" {
  type        = bool
  default     = false
  description = "Run a standby replica in another AZ. Recommended for prod (doubles the instance cost)."
}

variable "backup_retention_period" {
  type        = number
  default     = 7
  description = "Days to keep automated backups (0-35)."
}

variable "backup_window" {
  type        = string
  default     = null
  description = "Daily backup window in UTC, e.g. \"03:00-04:00\". If null, AWS picks one."
}

variable "maintenance_window" {
  type        = string
  default     = null
  description = "Weekly maintenance window in UTC, e.g. \"sun:04:30-sun:05:30\". If null, AWS picks one."
}

variable "deletion_protection" {
  type        = bool
  default     = true
  description = "Prevent the DB instance from being deleted. Set to false in dev to allow terraform destroy."
}

variable "skip_final_snapshot" {
  type        = bool
  default     = false
  description = "Skip the final snapshot on deletion. Set to true in dev."
}

variable "apply_immediately" {
  type        = bool
  default     = false
  description = "Apply changes immediately instead of in the next maintenance window."
}

variable "performance_insights_enabled" {
  type        = bool
  default     = false
  description = "Enable Performance Insights."
}

variable "enabled_cloudwatch_logs_exports" {
  type        = list(string)
  default     = null
  description = "Log types to export to CloudWatch. If null: [\"postgresql\", \"upgrade\"] for postgres, [\"error\"] for mysql."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to every resource created by this module."
}
