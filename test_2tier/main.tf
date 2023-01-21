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
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, 0)
  availability_zone       = data.aws_availability_zones.all.names[0]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_web" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, 2)
  availability_zone = data.aws_availability_zones.all.names[1]
}

resource "aws_subnet" "private_rds" {
  count  = 2
  vpc_id = aws_vpc.main.id
  #   cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, 4)
#   cidr_block    = [for i in range(1, 255, 2) : cidrsubnet("10.0.0.0/16", 8, i)]
  availability_zone = data.aws_availability_zones.all.names[count.index]
  tags = {
    Name = "private-rds-subnet-${count.index + 3}"
  }
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
  name        = "web"
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

resource "aws_security_group" "rds" {
  name        = "rds"
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

resource "aws_instance" "web" {
  count                  = 2
  ami                    = "ami-0ff8a91507f77f867"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web.id]
  #   subnet_id       = aws_subnet.private_web[count.index].id
  subnet_id = element(aws_subnet.private_web[*].id, 0)
  user_data = <<EOF
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
  #   subnet_ids  = [aws_subnet.private_rds.*.id]
  subnet_ids = values(zipmap(aws_subnet.private_rds[*].id, aws_subnet.private_rds[*].id))
}


resource "aws_db_instance" "rds" {
  count                     = 1
  engine                    = "mysql"
  engine_version            = "5.7"
  instance_class            = "db.t2.micro"
  storage_type              = "gp3"
  allocated_storage         = 20
  db_name                   = "mydb"
  username                  = "myuser"
  password                  = "mypassword"
  vpc_security_group_ids    = [aws_security_group.rds.id]
  db_subnet_group_name      = aws_db_subnet_group.rds.name
  publicly_accessible       = false
  skip_final_snapshot       = false
  final_snapshot_identifier = "mydb-final-snapshot"
}

