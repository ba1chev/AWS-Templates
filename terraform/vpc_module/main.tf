data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  public_count  = length(var.public_subnet_cidrs)
  private_count = length(var.private_subnet_cidrs)

  # Use the AZs passed in, otherwise the first N available AZs in the region.
  azs = length(var.azs) > 0 ? var.azs : slice(
    data.aws_availability_zones.available.names,
    0,
    max(local.public_count, local.private_count, 1)
  )

  # NAT needs a public subnet to live in and a private subnet to serve.
  create_nat        = var.enable_nat_gateway && local.public_count > 0 && local.private_count > 0
  nat_gateway_count = local.create_nat ? (var.single_nat_gateway ? 1 : local.public_count) : 0
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(var.tags, { Name = "${var.name}-vpc" })
}

# Strip every rule from the default security group so nothing can
# accidentally rely on it. Resources should use explicit security groups.
resource "aws_default_security_group" "default" {
  count = var.manage_default_security_group ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, { Name = "${var.name}-default-sg-do-not-use" })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  count = local.public_count > 0 ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, { Name = "${var.name}-igw" })
}

# Subnets
resource "aws_subnet" "public" {
  count = local.public_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index % length(local.azs)]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(
    var.tags,
    var.public_subnet_tags,
    {
      Name = "${var.name}-public-${local.azs[count.index % length(local.azs)]}"
      Tier = "public"
    }
  )
}

resource "aws_subnet" "private" {
  count = local.private_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index % length(local.azs)]

  tags = merge(
    var.tags,
    var.private_subnet_tags,
    {
      Name = "${var.name}-private-${local.azs[count.index % length(local.azs)]}"
      Tier = "private"
    }
  )
}

# NAT Gateway(s)
resource "aws_eip" "nat" {
  count = local.nat_gateway_count

  domain = "vpc"

  tags = merge(var.tags, { Name = "${var.name}-nat-eip-${count.index}" })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, { Name = "${var.name}-nat-${count.index}" })

  depends_on = [aws_internet_gateway.main]
}

# Route tables - public
resource "aws_route_table" "public" {
  count = local.public_count > 0 ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, { Name = "${var.name}-public-rt" })
}

resource "aws_route" "public_internet" {
  count = local.public_count > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main[0].id
}

resource "aws_route_table_association" "public" {
  count = local.public_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Route tables - private (one per private subnet, so per-AZ NAT works cleanly)
resource "aws_route_table" "private" {
  count = local.private_count

  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, { Name = "${var.name}-private-rt-${count.index}" })
}

resource "aws_route" "private_nat" {
  count = local.nat_gateway_count > 0 ? local.private_count : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index % local.nat_gateway_count].id
}

resource "aws_route_table_association" "private" {
  count = local.private_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
