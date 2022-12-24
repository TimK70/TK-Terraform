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

#3-VPC info
resource "aws_vpc" "my-vpc" { #Per instructions, we're using our default VPC
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "my-vpc"
    
  }
}
#4-Internet Gateway (IG) which will allow us to reach the internet. 
#--Will be put into the main route table.
resource "aws_internet_gateway" "ig_project" {
  tags = {
    Name = "ig_project"
  }
  vpc_id = aws_vpc.my-vpc.id
}

#5-Three public subnets, one for each EC2/AZ
resource "aws_subnet" "public_subnetA" {
  tags = {
    Name = "public_subnetA"
  }
  vpc_id            = aws_vpc.my-vpc.id
  availability_zone = "us-east-1a"
}
resource "aws_subnet" "public_subnetB" {
  tags = {
    Name = "public_subnetB"
  }
  vpc_id            = aws_vpc.my-vpc.id
  availability_zone = "us-east-1b"
}
resource "aws_subnet" "public_subnetC" {
  tags = {
    Name = "public_subnetC"
  }
  vpc_id            = aws_vpc.my-vpc.id
  availability_zone = "us-east-1c"
}
#6-Three private subnets:
resource "aws_subnet" "private_subnetA" {
  tags = {
    Name = "private_subnetA"
  }
  vpc_id            = aws_vpc.my-vpc.id
  availability_zone = "us-east-1a"
}
resource "aws_subnet" "private_subnetB" {
  tags = {
    Name = "private_subnetB"
  }
  vpc_id            = aws_vpc.my-vpc.id
  availability_zone = "us-east-1b"
}
resource "aws_subnet" "private_subnetC" {
  tags = {
    Name = "private_subnetC"
  }
  vpc_id            = aws_vpc.my-vpc.id
  availability_zone = "us-east-1c"
}
#7-Security group that will allow all traffic to webservers on port 80 & ssh from our IP:
resource "aws_security_group" "nginx_sg" {
  name        = "web_sg"
  description = "Enable HTTP access to ec2 instances"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "-1"
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
  }
}

resource "aws_instance" "my-webserverA" {
  ami             = "ami-09fe851c8e75cbbf8"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private_subnetA.id
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
resource "aws_instance" "my-webserverB" {
  ami             = "ami-09fe851c8e75cbbf8"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private_subnetB.id
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
resource "aws_instance" "my-webserverC" {
  ami             = "ami-09fe851c8e75cbbf8"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private_subnetC.id
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


