locals {
  # Allow-all egress, expressed in the same shape as user-supplied rules.
  default_egress_rules = var.allow_all_egress ? {
    all_ipv4 = { description = "Allow all outbound IPv4", ip_protocol = "-1", from_port = null, to_port = null, cidr_ipv4 = "0.0.0.0/0", cidr_ipv6 = null, prefix_list_id = null, referenced_security_group_id = null, self = false }
    all_ipv6 = { description = "Allow all outbound IPv6", ip_protocol = "-1", from_port = null, to_port = null, cidr_ipv4 = null, cidr_ipv6 = "::/0", prefix_list_id = null, referenced_security_group_id = null, self = false }
  } : {}

  egress_rules = merge(local.default_egress_rules, var.egress_rules)
}

# Rules are managed as separate aws_vpc_security_group_*_rule resources
# (AWS provider best practice) instead of inline ingress/egress blocks, so
# individual rules can be added/removed without touching the others.
resource "aws_security_group" "this" {
  name        = var.use_name_prefix ? null : var.name
  name_prefix = var.use_name_prefix ? "${var.name}-" : null
  description = var.description
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = var.name })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = var.ingress_rules

  security_group_id = aws_security_group.this.id
  description       = each.value.description

  ip_protocol = each.value.ip_protocol
  from_port   = each.value.ip_protocol == "-1" ? null : each.value.from_port
  to_port     = each.value.ip_protocol == "-1" ? null : coalesce(each.value.to_port, each.value.from_port)

  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.self ? aws_security_group.this.id : each.value.referenced_security_group_id

  tags = merge(var.tags, { Name = "${var.name}-ingress-${each.key}" })
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = local.egress_rules

  security_group_id = aws_security_group.this.id
  description       = each.value.description

  ip_protocol = each.value.ip_protocol
  from_port   = each.value.ip_protocol == "-1" ? null : each.value.from_port
  to_port     = each.value.ip_protocol == "-1" ? null : coalesce(each.value.to_port, each.value.from_port)

  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.self ? aws_security_group.this.id : each.value.referenced_security_group_id

  tags = merge(var.tags, { Name = "${var.name}-egress-${each.key}" })
}
