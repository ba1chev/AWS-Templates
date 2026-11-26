variable "name" {
  type        = string
  description = "Name prefix used for the VPC and all related resources (e.g. \"dev\", \"prod-core\")."
}

variable "vpc_cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for the VPC."

  validation {
    condition     = can(cidrhost(var.vpc_cidr_block, 0))
    error_message = "vpc_cidr_block must be a valid IPv4 CIDR block, e.g. 10.0.0.0/16."
  }
}

variable "azs" {
  type        = list(string)
  default     = []
  description = "Availability zones to spread subnets across. If empty, the first N available AZs in the region are used, where N is the larger of the public/private subnet counts."
}

variable "public_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
  description = "CIDR blocks for public subnets. One subnet is created per entry, placed in azs[i]."
}

variable "private_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
  description = "CIDR blocks for private subnets. One subnet is created per entry, placed in azs[i]."
}

variable "enable_dns_support" {
  type        = bool
  default     = true
  description = "Enable DNS resolution in the VPC."
}

variable "enable_dns_hostnames" {
  type        = bool
  default     = true
  description = "Enable DNS hostnames for instances in the VPC."
}

variable "map_public_ip_on_launch" {
  type        = bool
  default     = false
  description = "Auto-assign public IPv4 addresses to instances launched in public subnets. Off by default (AWS Security Hub control EC2.15)."
}

variable "enable_nat_gateway" {
  type        = bool
  default     = true
  description = "Create NAT gateway(s) so private subnets have outbound internet access. NAT gateways are billed per hour plus per GB processed."
}

variable "single_nat_gateway" {
  type        = bool
  default     = true
  description = "Use one shared NAT gateway (cheaper, single-AZ point of failure). Set to false to create one NAT gateway per public subnet/AZ (highly available)."
}

variable "manage_default_security_group" {
  type        = bool
  default     = true
  description = "Take over the VPC's default security group and remove all of its rules (CIS AWS Foundations / Security Hub EC2.2)."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to every resource created by this module."
}

variable "public_subnet_tags" {
  type        = map(string)
  default     = {}
  description = "Extra tags for public subnets (e.g. {\"kubernetes.io/role/elb\" = \"1\"} for EKS)."
}

variable "private_subnet_tags" {
  type        = map(string)
  default     = {}
  description = "Extra tags for private subnets (e.g. {\"kubernetes.io/role/internal-elb\" = \"1\"} for EKS)."
}
