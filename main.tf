terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.19.0"  # Pinned to 5.19.x with patch flexibility
    }
  }

  # ✅ Active remote backend configuration
  backend "s3" {
    bucket         = "myaws-terraform-deployment-bucket"  # Match your S3 bucket
    key            = "devops-project/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-lock-table"  # Prevents concurrent runs
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"

  # Optional: Assume role for better security (uncomment if needed)
  /*
  assume_role {
    role_arn = "arn:aws:iam::ACCOUNT_ID:role/TerraformRole"
  }
  */
}

# Security Group with improved rules
resource "aws_security_group" "web_server_sg" {
  name        = "web-server-sg"
  description = "Allow HTTP and SSH traffic"

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["197.210.79.91/32"]  # Replace with your public IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WebServerSG"
  }
}

# EC2 Instance with improved configuration
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.ubuntu.id  # Uses dynamic AMI lookup
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web_server_sg.id]
  key_name               = aws_key_pair.deployer.key_name
  user_data              = filebase64("${path.module}/user_data.sh")

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name    = "DevOps-WebServer"
    Project = "DevOps-Pipeline"
  }
}

# Dynamic AMI lookup for Ubuntu 22.04 LTS
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]  # Canonical
}

# SSH Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "aws-terraform-key"
  public_key = file("${path.module}/aws-terraform-key.pub")  # Replace with your key path
}

# Outputs
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web_server.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.web_server.public_dns
}
