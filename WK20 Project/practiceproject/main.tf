# ----- root/main.tf

#------------- Provider ---------------
#This is our provider, which is AWS, this allows VSCode to help auto complete
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.24.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" #This will be our defualt region for our infrastructure to deploy into. 
}


# ------------ VPC ----------------

#Next we will create a new VPC
resource "aws_vpc" "project" {     #we named it project
  cidr_block       = "10.0.0.0/16" #this is your CIDR range for the VPC
  instance_tenancy = "default"
  #Tags are not required but we want to keep our stuff semi organized
  tags = {
    Name = "Project"
  }
}

#This IG will allows us to reach the internet, it will go into the public route table
resource "aws_internet_gateway" "project_gw" {
  vpc_id = aws_vpc.project.id #Here is is referencing the VPC we are creating 

  tags = {
    Name = "Project"
  }
}

# ----------------Subnets-----------------
#We are going to create four subnets, 2 public in AZ's 1a and 1b, 
#And 2 private subnets in AZ's 1a and 1b
resource "aws_subnet" "public_project_subnet_1a" {
  vpc_id            = aws_vpc.project.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Project"
  }
}

resource "aws_subnet" "public_project_subnet_1b" {
  vpc_id            = aws_vpc.project.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "Project"
  }
}

#Private subnets 
resource "aws_subnet" "private_project_subnet_1a" {
  vpc_id            = aws_vpc.project.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Project"
  }
}

resource "aws_subnet" "private_project_subnet_1b" {
  vpc_id            = aws_vpc.project.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "Project"
  }
}


#--------Route Tables------------
#We will provision 3 subnets Our defualt route table, a public route table and a private route table
#Default RT so that our instances that are not associated with a RT will go here 
#This is incase but also so they wouldnt be in a RT with an IGW if they was to be provisioned in Defualt
resource "aws_default_route_table" "project_default" {
  default_route_table_id = aws_vpc.project.default_route_table_id
}


#Public Route Table and RT Association
resource "aws_route_table" "public_project_route_table" {
  vpc_id = aws_vpc.project.id

  route {
    cidr_block = "0.0.0.0/0" # must be open for igw to point to
    gateway_id = aws_internet_gateway.project_gw.id
  }

  tags = {
    Name = "Project"
  }
}

#This associates our public routes to the the route table. 
resource "aws_route_table_association" "public_route_1" {
  subnet_id      = aws_subnet.public_project_subnet_1a.id
  route_table_id = aws_route_table.public_project_route_table.id
}

resource "aws_route_table_association" "public_route_2" {
  subnet_id      = aws_subnet.public_project_subnet_1b.id
  route_table_id = aws_route_table.public_project_route_table.id
}


#Private route table and RT Association
resource "aws_route_table" "private_project_route_table" {
  vpc_id = aws_vpc.project.id

  tags = {
    Name = "Project"
  }
}

#This associtates our routes to the private route table.
resource "aws_route_table_association" "private_route_1" {
  subnet_id      = aws_subnet.private_project_subnet_1a.id
  route_table_id = aws_route_table.private_project_route_table.id
}

resource "aws_route_table_association" "private_route_2" {
  subnet_id      = aws_subnet.private_project_subnet_1b.id
  route_table_id = aws_route_table.private_project_route_table.id
}


# -------- Load Balancer ---------
#When creating load balancer you need more that just the load balancer resource
#You have to include the Load Balancer resource, the load balancer listener, target group, and target group attachements 
resource "aws_lb" "project_lb" {
  name               = "project-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_ALB.id]
  subnets            = [aws_subnet.public_project_subnet_1a.id, aws_subnet.public_project_subnet_1b.id]

  enable_deletion_protection = false # if true it can cuase problems or it wont destroy
  access_logs {
    bucket  = "devin-1993"
    prefix  = "test-lb"
    enabled = true
  }

  tags = {
    Environment = "project"
  }
}

resource "aws_lb_listener" "project_lb_listener" {
  load_balancer_arn = aws_lb.project_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.project_lb_tg.arn
  }
}

resource "aws_lb_target_group" "project_lb_tg" {
  name     = "project-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.project.id
}
#These attachements attach our instances to our target group
resource "aws_lb_target_group_attachment" "project" {
  target_group_arn = aws_lb_target_group.project_lb_tg.arn
  target_id        = aws_instance.project_front_end_1a.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "project2" {
  target_group_arn = aws_lb_target_group.project_lb_tg.arn
  target_id        = aws_instance.project_front_end_1b.id
  port             = 80
}

#--------------Security Groups -------------
#will need to add a loadbalancer SG, a WebTier SG and a Database SG

resource "aws_security_group" "public_ALB" {
  name        = "HTTP_Access_via_ALB"
  description = "Allow HTTP inbound traffic via ALB"
  vpc_id      = aws_vpc.project.id #must be specififed

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols 
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project"
  }
}

resource "aws_security_group" "public_http_sg" {
  name        = "HTTP_Access"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.project.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.public_ALB.id] #since we are only allowing traffic from the SG we must specifiy name instead of CIDR
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols 
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project"
  }
}


resource "aws_security_group" "private_database_sg" {
  name        = "MYSQL_Access"
  description = "Allow MYSQL inbound traffic"
  vpc_id      = aws_vpc.project.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.public_http_sg.id] #the sg from the http only----------
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols 
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project"
  }
}



# ---------- Instances --------

resource "aws_instance" "project_front_end_1a" {
  ami                         = "ami-090fa75af13c156b4"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.public_http_sg.id]
  subnet_id                   = aws_subnet.public_project_subnet_1a.id
  associate_public_ip_address = true
  user_data                   = file("./userdata.tpl")
  key_name                    = aws_key_pair.key_pair.key_name #had to specifiy the name

  tags = {
    Name = "project"
  }
}


resource "aws_key_pair" "key_pair" {
  key_name   = "tfkey.pub"
  public_key = file("/Users/devin/.ssh/tfkey.pub") #The pub mean it is a public key pair and not our private one,                           
}                                                  #This is the path to our key on our machine

resource "aws_instance" "project_front_end_1b" {
  ami                         = "ami-090fa75af13c156b4"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.public_http_sg.id]
  key_name                    = aws_key_pair.key_pair.key_name
  subnet_id                   = aws_subnet.public_project_subnet_1b.id
  user_data                   = file("./userdata.tpl")
  associate_public_ip_address = true

  tags = {
    Name = "project"
  }
}


#---------RDS-----------
#This is going to be our RDS Mysql database, it will be on a t2.micro
#Attached is the database SG
#along with the subnet group that the RDS will deploy into. 
#the subnet group has both our private Subnets to deploy into. 
resource "aws_db_instance" "project" {
  allocated_storage      = 8
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  db_name                = "mydb"
  db_subnet_group_name   = aws_db_subnet_group.project.name #must be specified or it will be created in Defualt VPC
  username               = "foo"
  password               = "foobarbaz"
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.private_database_sg.id]
}

resource "aws_db_subnet_group" "project" {
  name       = "project"
  subnet_ids = [aws_subnet.private_project_subnet_1a.id, aws_subnet.private_project_subnet_1b.id]

  tags = {
    Name = "My DB subnet group"
  }
}

# ------------- Outputs-------------

output "PublicIP" {
  description = "Public IP of EC2 instance"
  value       = aws_instance.project_front_end_1a.public_ip
}
output "PublicIP2" {
  description = "Public IP of EC2 instance"
  value       = aws_instance.project_front_end_1b.public_ip
}

output "ALB_DNS" {
  description = "The ALBs DNS"
  value       = aws_lb.project_lb.dns_name