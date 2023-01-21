provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "all" {}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index+1}.0/24"
  availability_zone       = data.aws_availability_zones.all.names[count.index]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_web" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index+2}.0/24"
  availability_zone       = data.aws_availability_zones.all.names[count.index]
  map_public_ip_on_launch = false
}

resource "aws_subnet" "private_rds" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index+3}.0/24"
  availability_zone       = data.aws_availability_zones.all.names[count.index]
  map_public_ip_on_launch = false
}

resource "aws_security_group" "bastion" {
  name   = "bastion"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web" {
  name   = "web"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds" {
  name   = "rds"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  count           = 2
  ami             = "ami-0ff8a91507f77f867"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.web.name]
  subnet_id       = aws_subnet.private_web[count.index].id
  user_data       = <<EOF
    #!/bin/bash
    sudo yum install -y nginx
    sudo service nginx start
  EOF
}

# resource "aws_db_subnet_group" "rds" {
#   name = "private_rds_subnet_group"
#   description = "Subnet group for private RDS instances"
#   subnet_ids = [aws_subnet.private_rds[*].id]
# }
resource "aws_db_subnet_group" "rds" {
  name        = "private_rds_subnet_group"
  description = "Subnet group for private RDS instances"
  subnet_ids  = [for subnet in aws_subnet.private_rds : subnet.id]
}


resource "aws_db_instance" "rds" {
  count                  = 1
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  storage_type           = "gp3"
  allocated_storage      = 20
  db_name                = "mydb"
  username               = "myuser"
  password               = "mypassword"
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  publicly_accessible    = false
}

