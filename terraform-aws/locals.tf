#---  root/locals.tf ---

# local cidr block value for VPC
locals {
  vpc_cidr = "10.12.0.0/16"
}

locals {
  security_groups = {
    public = {
      name        = "my_public_sg"
      description = "Security Group for public Access"
      ingress = {
        ssh = {
          from        = 22
          to          = 22
          protocol    = "tcp"
          cidr_blocks = [var.access_ip]
        }
        http = {
            from = 80
            to = 80
            protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }
      }      
    }
    rds = {
      name        = "rds_sg"
      description = "rds access"
      ingress = {
        mysql = {
          from        = 3306
          to          = 3306
          protocol    = "tcp"
          cidr_blocks = [local.vpc_cidr]
        }
      }
    }
  }
}

