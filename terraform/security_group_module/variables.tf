variable "name" {
  type        = string
  description = "Name of the security group. Used as a prefix when use_name_prefix = true."
}

variable "use_name_prefix" {
  type        = bool
  default     = true
  description = "Use name as a prefix (AWS appends a unique suffix). Lets Terraform replace the group without a name clash (create_before_destroy)."
}

variable "description" {
  type        = string
  default     = "Managed by Terraform"
  description = "Description of the security group. Changing it forces a replacement."
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC the security group belongs to."
}

variable "ingress_rules" {
  description = <<-EOT
    Inbound rules, keyed by a stable name (e.g. "https", "ssh_from_office").
    Each rule needs exactly one source: cidr_ipv4, cidr_ipv6, prefix_list_id,
    referenced_security_group_id, or self = true.
    ip_protocol: "tcp" (default), "udp", "icmp", or "-1" for all traffic
    (from_port/to_port must be omitted for "-1"). to_port defaults to from_port.
  EOT
  type = map(object({
    description                  = optional(string)
    ip_protocol                  = optional(string, "tcp")
    from_port                    = optional(number)
    to_port                      = optional(number)
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
    self                         = optional(bool, false)
  }))
  default = {}

  validation {
    condition = alltrue([
      for r in values(var.ingress_rules) : length([
        for s in [r.cidr_ipv4, r.cidr_ipv6, r.prefix_list_id, r.referenced_security_group_id, r.self ? "self" : null] : s if s != null
      ]) == 1
    ])
    error_message = "Each ingress rule must set exactly one of: cidr_ipv4, cidr_ipv6, prefix_list_id, referenced_security_group_id, self = true."
  }

  validation {
    condition = alltrue([
      for r in values(var.ingress_rules) : r.ip_protocol == "-1" ? (r.from_port == null && r.to_port == null) : r.from_port != null
    ])
    error_message = "Rules with ip_protocol = \"-1\" must not set ports; all other rules must set from_port."
  }
}

variable "egress_rules" {
  description = "Outbound rules, same shape as ingress_rules. Added on top of the allow-all rule when allow_all_egress = true."
  type = map(object({
    description                  = optional(string)
    ip_protocol                  = optional(string, "tcp")
    from_port                    = optional(number)
    to_port                      = optional(number)
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
    self                         = optional(bool, false)
  }))
  default = {}

  validation {
    condition = alltrue([
      for r in values(var.egress_rules) : length([
        for s in [r.cidr_ipv4, r.cidr_ipv6, r.prefix_list_id, r.referenced_security_group_id, r.self ? "self" : null] : s if s != null
      ]) == 1
    ])
    error_message = "Each egress rule must set exactly one of: cidr_ipv4, cidr_ipv6, prefix_list_id, referenced_security_group_id, self = true."
  }

  validation {
    condition = alltrue([
      for r in values(var.egress_rules) : r.ip_protocol == "-1" ? (r.from_port == null && r.to_port == null) : r.from_port != null
    ])
    error_message = "Rules with ip_protocol = \"-1\" must not set ports; all other rules must set from_port."
  }
}

variable "allow_all_egress" {
  type        = bool
  default     = true
  description = "Add an allow-all outbound rule (0.0.0.0/0 and ::/0), matching AWS's default behaviour. Set to false to lock egress down to egress_rules only."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to the security group and its rules."
}
