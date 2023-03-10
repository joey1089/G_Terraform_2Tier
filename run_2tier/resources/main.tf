# --- resouces/main.tf ---

# Deploy VPC
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main-vpc"
  }
}

# Deploy Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw"
  }
}

# Deploy 2 Public Subnets
resource "aws_subnet" "sub_public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "sub-public-1"
  }
}

resource "aws_subnet" "sub_public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "sub-public-2"
  }
}

# Deploy 2 Private Subnets
resource "aws_subnet" "sub_private_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "sub-private-1"
  }
}

resource "aws_subnet" "sub_private_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "sub-private-2"
  }
}

# Deploy Route Table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "routetable"
  }
}

# Associate Subnets With Route Table
resource "aws_route_table_association" "route1" {
  subnet_id      = aws_subnet.sub_public_1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "route2" {
  subnet_id      = aws_subnet.sub_public_2.id
  route_table_id = aws_route_table.rt.id
}

# Deploy Security Groups
resource "aws_security_group" "http_ssh_sg" {
  name        = "http_ssh_sg"
  description = "Allow traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_security_group" "rds_private_sg" {
  name        = "rds_private_sg"
  description = "Allow traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    cidr_blocks     = ["10.0.0.0/16"]
    security_groups = [aws_security_group.http_ssh_sg.id]
  }
  ingress {
    from_port   = 22
    to_port     = 22
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

# Deploy ALB Security Group
resource "aws_security_group" "alb_security_grp" {
  name        = "alb_security_grp"
  description = "ALB Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Deploy Application Load Balancer
resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_grp.id]
  subnets            = [aws_subnet.sub_public_1.id, aws_subnet.sub_public_2.id]
}

# Create ALB Target Group
resource "aws_lb_target_group" "LB_tar_grp" {
  name     = "LB-tar-grp"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  depends_on = [aws_vpc.main]
}

# Deploy LB Target Attachments
resource "aws_lb_target_group_attachment" "tgattach1" {
  target_group_arn = aws_lb_target_group.LB_tar_grp.arn
  target_id        = aws_instance.instance1.id
  port             = 80

  depends_on = [aws_instance.instance1]
}

resource "aws_lb_target_group_attachment" "tg_attach2" {
  target_group_arn = aws_lb_target_group.LB_tar_grp.arn
  target_id        = aws_instance.instance2.id
  port             = 80

  depends_on = [aws_instance.instance2]
}

# Deploy LB Listener
resource "aws_lb_listener" "lblisten" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.LB_tar_grp.arn
  }
}

# Deploy EC2 Instances
resource "aws_instance" "instance1" {
  ami                         = "ami-0b0dcb5067f052a63"
  instance_type               = "t2.micro"
  key_name                    = "Test_KeyPair"
  availability_zone           = "us-east-1a"
  vpc_security_group_ids      = [aws_security_group.http_ssh_sg.id]
  subnet_id                   = aws_subnet.sub_public_1.id
  associate_public_ip_address = true
  user_data                   = file(var.user-install)

  tags = {
    Name = "ec2instance1"
  }
}
resource "aws_instance" "instance2" {
  ami                         = "ami-0b0dcb5067f052a63"
  instance_type               = "t2.micro"
  key_name                    = "Test_KeyPair"
  availability_zone           = "us-east-1b"
  vpc_security_group_ids      = [aws_security_group.http_ssh_sg.id]
  subnet_id                   = aws_subnet.sub_public_2.id
  associate_public_ip_address = true
  user_data                   = file(var.user-install)

  tags = {
    Name = "ec2instance2"
  }
}

# Relational Database Service Subnet Group
resource "aws_db_subnet_group" "dbsubnet" {
  name       = "dbsubnet"
  subnet_ids = [aws_subnet.sub_private_1.id, aws_subnet.sub_private_2.id]
}

# Create RDS Instance
resource "aws_db_instance" "rds_instance" {
  allocated_storage      = 8
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  identifier             = "dbinstance"
  db_name                = "db_mysql"
  username               = "admin"
  password               = "password"
  db_subnet_group_name   = aws_db_subnet_group.dbsubnet.id
  vpc_security_group_ids = [aws_security_group.rds_private_sg.id]
  skip_final_snapshot    = true  
}