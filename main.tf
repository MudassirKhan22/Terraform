terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.21.0"
    }
  }
  
  backend "s3" {
    bucket = "tf-backend-sample"
    key = "terraform.tfstate"
    region = "ap-south-1"
    dynamodb_table = "tf-sample"
    
  }

}

provider "aws" {
  region     = "ap-south-1"
  # access_key = "my-access-key"
  # secret_key = "my-secret-key"
}

# variable "instance_type"{}

# resource "aws_instance" "web" {
#   count = 2
#   ami           = "ami-0b41f7055516b991a"
#   instance_type = var.instance_type

#   tags = {
#     Name = "${terraform.workspace}-${count.index}"
#   }
# }

#Creating the vpc
resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name= "my-vpc"
  }
}

#Creating the subnet
resource "aws_subnet" "my-subnet" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "my-subnet"
  }
}

#Creating Internet Gateway
resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "my-igw"
  }
}

#Creating the route table
resource "aws_route_table" "my-rt" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-igw.id
  }
}

#Creating the route table association.
resource "aws_route_table_association" "my-rt-association" {
  subnet_id      = aws_subnet.my-subnet.id
  route_table_id = aws_route_table.my-rt.id
}

#Creating the security groups.
resource "aws_security_group" "my-sg" {
  name        = "my-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

   ingress {
    description      = "HTTP"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "my-sg"
  }
}

#Data-source for ami
data "aws_ami" "my_ami"{
  most_recent = true

filter {
  name= "name"
  values = ["amzn2-ami-kernel-*-x86_64-gp2"]

}

filter {
  name = "virtualization-type"
  values = ["hvm"]
}

owners = ["amazon"]
}


#Creating the ec2-instance
 resource "aws_instance" "web" {
  #ami           = "ami-0b41f7055516b991a"
  ami = data.aws_ami.my_ami.id
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id = aws_subnet.my-subnet.id
  vpc_security_group_ids = [aws_security_group.my-sg.id]
  key_name = "Linux12345"
  user_data = file("server-script.sh")

  tags = {
    Name = "my-web-server"
  }
}

output "ip" {
  value = aws_instance.web.public_ip
}




