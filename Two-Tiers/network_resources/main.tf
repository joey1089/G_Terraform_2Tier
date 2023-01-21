# --- network_resources/main.tf ---

# Creating random interger to generate random id
resource "random_integer" "random" {
  min = 1
  max = 100
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "main-${random_integer.random.id}"
  }
}

resource "aws_subnet" "public_subnet" {
  count                   = length(var.public_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "public-subnet${count.index + 1}"
  }
}

resource "aws_subnet" "web_private_subnet" {
  count                   = length(var.private_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_cidrs[count.index]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "web-private_${count.index + 1}"
  }
}

resource "aws_subnet" "rds_private_subnet" {
  count                   = length(var.rds_private_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.rds_private_cidrs[count.index]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "RDS-private_subnet${count.index + 1}"
  }
}

resource "aws_security_group" "bastion_security_group" {
  name   = "bastion-security-group"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web_security_group" {
  name        = "web_security_group"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_security_group" {
  name        = "rds_security_group"
  description = "Security group for RDS instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# resource "aws_instance" "web" {
#   count                  = 2
#   ami                    = "ami-0ff8a91507f77f867"
#   instance_type          = "t2.micro"
#   vpc_security_group_ids = [aws_security_group.web_security_group.id]
#   #   subnet_id       = aws_subnet.private_web[count.index].id
#   subnet_id = element(aws_subnet.web_private_subnet[*].id, 0)
#   user_data = <<EOF
#     #!/bin/bash
#     sudo yum update -y
#     sudo yum install -y nginx
#     sudo service nginx start

#   EOF
# }

# resource "aws_db_subnet_group" "rds" {
#   name = "private_rds_subnet_group"
#   description = "Subnet group for private RDS instances"
#   subnet_ids = [aws_subnet.private_rds[*].id]
# }
resource "aws_db_subnet_group" "rds_sub_grp" {
  # count = var.db_subnet_group == true ? 1 : 0
  name        = "private_rds_subnet_group"
  description = "Subnet group for private RDS instances"
  # subnet_ids  = [aws_subnet.rds_private_subnet[*].id] 
  subnet_ids = values(zipmap(aws_subnet.rds_private_subnet[*].id, aws_subnet.rds_private_subnet[*].id))
  tags = {
    Name = "aws_rds_subnet_group"
  }
}


resource "aws_db_instance" "rds" {
  count             = 1
  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "db.t2.micro"
  storage_type      = "gp2"
  allocated_storage = 12
  db_name           = "mydb"
  username          = "myuser"
  password          = "mypassword"
  # vpc_security_group_ids    = [aws_security_group.rds_sub_grp.id]
  # vpc_security_group_ids    = ["aws_db_subnet_group.rds_sub_grp.subnet_ids"]
  vpc_security_group_ids    = aws_security_group.rds_security_group.id
  # db_subnet_group_name      = aws_db_subnet_group.rds_sub_grp.name
  db_subnet_group_name = aws_db_subnet_group.rds_sub_grp.name
  publicly_accessible       = false
  skip_final_snapshot       = false
  final_snapshot_identifier = "mydb-final-snapshot"
}