#1-Providers section:
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.48.0"
    }
  }
}
#2-This will be our default region. If you're using an IDE other than Cloud9, you will
# put your access_key and secret_key here, below region =.
provider "aws" {
  region = "us-east-1"
}

# resource "aws_key_pair" "wk20kp" {
#   key_name = "wk20kp"
#   public_key = ""
# }
#3-VPC info
resource "aws_default_vpc" "defaultVPC" {
  tags = {
    Name = "defaultVPC"
  }
}
#Internet Gateway (IG) which will allow us to reach the internet. 
#--Will be put into the main route table.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_default_vpc.defaultVPC.id
  tags = {
    Name = "igw"
  }
}
resource "aws_default_subnet" "default_az1" {
  availability_zone = "us-east-1a"

  tags = {
    Name = "Default subnet for us-east-1a"
  }
}
resource "aws_default_subnet" "default_az2" {
  availability_zone = "us-east-1b"

  tags = {
    Name = "Default subnet for us-east-1b"
  }
}
resource "aws_default_subnet" "default_az3" {
  availability_zone = "us-east-1c"

  tags = {
    Name = "Default subnet for us-east-1c"
  }
}
resource "aws_default_route_table" "mainRT" {
  default_route_table_id = aws_default_vpc.defaultVPC.default_route_table_id

  route {
    cidr_block = "10.0.1.0/24"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "igw"
  }
}
resource "aws_default_security_group" "default" {
  vpc_id = aws_default_vpc.defaultVPC.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#
#7-Security group that will allow all traffic to webservers on port 80 & ssh from our IP:
resource "aws_security_group" "nginx_sg" {
  name        = "web_sg"
  description = "Enable HTTP access to ec2 instances"
  vpc_id      = aws_default_vpc.defaultVPC.id

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
# Application Load Balancer--Internet facing
resource "aws_alb" "alb" {
  name               = "alb"
  load_balancer_type = "application"
  internal           = false
  subnets            = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id, aws_default_subnet.default_az3.id]
  security_groups    = [aws_default_security_group.default.id]
}
resource "aws_instance" "my-webserver1" {
  ami             = "ami-09fe851c8e75cbbf8"
  instance_type   = "t2.micro"
  subnet_id       = aws_default_subnet.default_az1.id
  security_groups = [aws_security_group.nginx_sg.id]

  user_data = <<-EOF
    "#!/bin/bash
    yum -y update
    yum -y install nginx
    systemctl start nginx
    systemctl enable nginx
    echo "<h2>My NGINX Webserver</h2><br>Built by Terraform" > /var/www/html/index.html"
    EOF

}
resource "aws_instance" "my-webserver2" {
  ami             = "ami-09fe851c8e75cbbf8"
  instance_type   = "t2.micro"
  subnet_id       = aws_default_subnet.default_az2.id
  security_groups = [aws_security_group.nginx_sg.id]

  user_data = <<-EOF
    "#!/bin/bash
    yum -y update
    yum -y install nginx
    systemctl start nginx
    systemctl enable nginx
    echo "<h2>My NGINX Webserver</h2><br>Built by Terraform" > /var/www/html/index.html"
    EOF
}
resource "aws_instance" "my-webserver3" {
  ami             = "ami-09fe851c8e75cbbf8"
  instance_type   = "t2.micro"
  subnet_id       = aws_default_subnet.default_az3.id
  security_groups = [aws_security_group.nginx_sg.id]

  user_data = <<-EOF
    "#!/bin/bash
    yum -y update
    yum -y install nginx
    systemctl start nginx
    systemctl enable nginx
    echo "<h2>My NGINX Webserver</h2><br>Built by Terraform" > /var/www/html/index.html"
    EOF
}


