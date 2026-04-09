# ------------------------------------------------------------------------------
# TERRAFORM SETTINGS & BACKEND
# ------------------------------------------------------------------------------

terraform {
  # Locking the version ensures compatibility across different environments
  required_version = "~> 1.14.0"

  # EMPTY BACKEND BLOCK: 
  # This is a "Partial Configuration." The 'manage.sh' script will 
  # automatically provide the bucket, key, and region details during 
  # 'terraform init -backend-config=backend.conf'.
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ------------------------------------------------------------------------------
# PROVIDER CONFIGURATION
# ------------------------------------------------------------------------------

provider "aws" {
  region = "us-west-2" # Ensure this matches your backend bucket region
}

# ------------------------------------------------------------------------------
# DATA SOURCES
# ------------------------------------------------------------------------------

# Dynamically fetches the most recent Amazon Linux 2023 AMI ID.
# This ensures your automation doesn't break when old AMIs are retired.
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-kernel-6.1-x86_64"]
  }
}

# ------------------------------------------------------------------------------
# RESOURCES: EC2 INSTANCE
# ------------------------------------------------------------------------------

resource "aws_instance" "app_server" {
  # Uses the ID found by the data source above
  ami           = data.aws_ami.latest_amazon_linux.id
  instance_type = "t3.micro"

  # Tags are essential for tracking resources in a professional AWS account
  tags = {
    Name        = "SDET_Automation_Demo"
    Environment = "Dev"
    Project     = "Terraform_Remote_State"
  }
}

# ------------------------------------------------------------------------------
# OUTPUTS
# ------------------------------------------------------------------------------

output "instance_public_ip" {
  value       = aws_instance.app_server.public_ip
  description = "The public IP address of the newly created EC2 instance"
}
