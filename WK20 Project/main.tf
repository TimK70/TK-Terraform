# ------/root/main.tf-----------------

#1-Providers section:
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.24.0"
    }
  }
}
#2-This will be our default region. If you're using an IDE other than Cloud9, you will
# put your access_key and secret_key here, below region =.
provider "aws" {
  region = "us-east-2"
}
#Key pair information
# resource "aws_key_pair" "TF_project" {
#   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCLoyH6wDNkA2pMkvXkzWRz/WJvnuwrXWFBDXdSJ+pt+IHyv65Ost2l58JEu3SAKGFDvKVHzahpLPRK0hkaW9l62MfpfKKyk5nfdHTlzwzIxukJwgYZeQB/bGOeM1eKTe22aPPlSVQW1D/MLMwvxO9ZErfguM7Gtw9Ev+MWOV0dPif+XLT7LsC11s3oWv6+r3rGJ6818yZ/ut4oYXHGZoBumUBzsKK8HF5qKqCfcC5TxjrGISeROZvVKuFhZ0VY2KCk4q1hI0OO3Cl/fuq/7ED1sTc7/K/m3vK3ZWkAs4LBn/2yQMSZ+rpkymqUsabXkI7FuDXBFvcvaVYZIHWYG5bB"
#   key_name = "TF_project"
#}

#3-VPC info
resource "aws_vpc" "defaultVPC" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "defaultVPC"
  }
}
#Internet Gateway (IG) which will allow us to reach the internet. 
#--Will be put into the main route table.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.defaultVPC.id
  tags = {
    Name = "defaultVPC_igw"
  }
}
resource "aws_subnet" "default_az1" {
  vpc_id            = aws_vpc.defaultVPC.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2a"
  tags = {
    Name = "subnet for us-east-2a"
  }
}
resource "aws_subnet" "default_az2" {
  vpc_id            = aws_vpc.defaultVPC.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-2b"
  tags = {
    Name = "subnet for us-east-2b"
  }
}
resource "aws_subnet" "default_az3" {
  vpc_id            = aws_vpc.defaultVPC.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-2c"
  tags = {
    Name = "subnet for us-east-2c"
  }
}

#Create a Route Table to go with the igw
resource "aws_route_table" "igw_public_rt" {
  vpc_id = aws_vpc.defaultVPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
    }
  tags = {
    Name = "Route Table"
  }
}
#Here, we will pair up our Public Rout Table to our Public Subnets
resource "aws_route_table_association" "route2a" {
  subnet_id      = aws_subnet.default_az1.id
  route_table_id = aws_route_table.igw_public_rt.id
}
resource "aws_route_table_association" "route2b" {
  subnet_id      = aws_subnet.default_az2.id
  route_table_id = aws_route_table.igw_public_rt.id
}
resource "aws_route_table_association" "public2c" {
  subnet_id      = aws_subnet.default_az3.id
  route_table_id = aws_route_table.igw_public_rt.id
}

#7-Security group that will allow all traffic to webservers on port 80 & ssh from our IP:
resource "aws_security_group" "HTTP_sg" {
  name        = "HTTP_sg"
  description = "Enable HTTP and SSH access to ec2 instances"
  #Allow SSH access.
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #Allow incoming HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #Allow outgoing--access to web.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "webserver1" {
  ami             = "ami-0a606d8395a538502"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.default_az1.id
  security_groups = [aws_security_group.HTTP_sg.id]
  key_name        = "TF_project1"

  user_data = <<-EOF
    #!/bin/bash
    yum -y update
    yum -y install nginx
    systemctl start nginx
    systemctl enable nginx
    echo ""<h1>My NGINX Webserver</h1><br>Built by Terraform" > /var/www/html/index.html"

}

resource "aws_instance" "webserver2" {
  ami                         = "ami-0a606d8395a538502"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.default_az2.id
  security_groups             = [aws_security_group.HTTP_sg.id]
  key_name = "TF_project2"

  user_data = <<-EOF
    #!/bin/bash
    yum -y update
    yum -y install nginx
    systemctl start nginx
    systemctl enable nginx
    echo ""<h1>My NGINX Webserver</h1><br>Built by Terraform" > /var/www/html/index.html"
    EOF
}

resource "aws_instance" "webserver3" {
  ami             = "ami-0a606d8395a538502"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.default_az3.id
  security_groups = [aws_security_group.HTTP_sg.id]
  key_name        = "TF_project3"

  user_data = <<-EOF
    #!/bin/bash
    yum -y update
    yum -y install nginx
    systemctl start nginx
    systemctl enable nginx
    echo ""<h2>My NGINX Webserver</h2><br>Built by Terraform" > /var/www/html/index.html"
    EOF
}


