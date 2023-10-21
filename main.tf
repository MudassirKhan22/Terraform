terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.21.0"
    }
  }

}

provider "aws" {
  region     = "ap-south-1"
  # access_key = "my-access-key"
  # secret_key = "my-secret-key"
}

variable "instance_type"{}

resource "aws_instance" "web" {
  count = 2
  ami           = "ami-0b41f7055516b991a"
  instance_type = var.instance_type

  tags = {
    Name = "${terraform.workspace}-${count.index}"
  }
}
