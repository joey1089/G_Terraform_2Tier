# --- networking/main.tf ---

data "aws_availability_zones" "available" {} #state = available # will only get currently available zone

resource "random_integer" "random" {
  min = 1
  max = 100
}

resource "random_shuffle" "az_list" {
  input        = data.aws_availability_zones.available.names
  result_count = var.max_subnets
}

resource "aws_vpc" "myvpc_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "my_vpc-${random_integer.random.id}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "my_sg" {
  for_each    = var.security_groups
  name        = each.value.name
  description = each.value.description
  vpc_id      = aws_vpc.myvpc_vpc.id
  dynamic "ingress" {
    for_each = each.value.ingress
    content {
      from_port   = ingress.value.from
      to_port     = ingress.value.to
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "mypublic_subnet" {
  count                   = var.public_sn_count
  vpc_id                  = aws_vpc.myvpc_vpc.id
  cidr_block              = var.public_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = random_shuffle.az_list.result[count.index]
  # availability_zone = data.aws_availability_zones.available.names[count.index]
  # availability_zone = ["us-west-2a", "us-west-2b", "us-west-2c", "us-west-2d"][count.index]
  tags = {
    Name = "mypublic-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "myprivate_subnet" {
  count             = var.private_sn_count
  vpc_id            = aws_vpc.myvpc_vpc.id
  cidr_block        = var.private_cidrs[count.index]
  availability_zone = random_shuffle.az_list.result[count.index]
  # availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "myprivate-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.myvpc_vpc.id
  tags = {
    Name = "my-IGW"
  }
}

resource "aws_route_table" "my_public_RT" {
  vpc_id = aws_vpc.myvpc_vpc.id
  tags = {
    Name = "my-public-RT"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.my_public_RT.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.IGW.id
}

resource "aws_default_route_table" "my_private_rt" {
  default_route_table_id = aws_vpc.myvpc_vpc.default_route_table_id
  tags = {
    Name = "my-private-RT"
  }
}

#Create Public Route Table association
resource "aws_route_table_association" "Public_RT_association" {
  count          = var.public_sn_count
  subnet_id      = aws_subnet.mypublic_subnet.*.id[count.index]
  route_table_id = aws_route_table.my_public_RT.id
}