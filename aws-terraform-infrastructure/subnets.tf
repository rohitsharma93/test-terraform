# --- Public Subnets (for ALB, NAT GW) ---
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name                     = "${local.name_prefix}-public-subnet-${count.index + 1}"
    Tier                     = "Public"
    "kubernetes.io/role/elb" = "1"
  })
}

# --- Private Application Subnets (for EC2 / ASG) ---
resource "aws_subnet" "private_app" {
  count             = length(var.private_app_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.common_tags, {
    Name                              = "${local.name_prefix}-private-app-subnet-${count.index + 1}"
    Tier                              = "Private-App"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

# --- Private Database Subnets (for RDS) ---
resource "aws_subnet" "private_db" {
  count             = length(var.private_db_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_db_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-db-subnet-${count.index + 1}"
    Tier = "Private-DB"
  })
}

# --- DB Subnet Group ---
resource "aws_db_subnet_group" "rds" {
  name        = "${local.name_prefix}-db-subnet-group"
  description = "Subnet group for demo RDS PostgreSQL instance"
  subnet_ids  = aws_subnet.private_db[*].id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-db-subnet-group"
  })
}
