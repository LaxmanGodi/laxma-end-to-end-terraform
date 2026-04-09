# ------------------------------------------------------------------------------
# TERRAFORM CONFIGURATION
# ------------------------------------------------------------------------------

terraform {
  # Ensures all team members use the same Terraform version (v1.14.x)
  required_version = "~> 1.14.0"

  # AWS Provider handles the communication with your AWS account
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# The AWS Region where your state files will be stored
provider "aws" {
  region = "us-west-2"
}

# ------------------------------------------------------------------------------
# DYNAMIC VARIABLES (LOCALS)
# ------------------------------------------------------------------------------

# Fetches your 12-digit AWS Account ID dynamically to ensure bucket uniqueness
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# ------------------------------------------------------------------------------
# S3 BUCKET: THE "BRAIN" STORAGE
# Stores the .tfstate file so it's accessible from any machine (not just local)
# ------------------------------------------------------------------------------

resource "aws_s3_bucket" "terraform_state" {
  # Standard naming convention: AccountID-purpose
  bucket = "${local.account_id}-terraform-states"
  
  # CRITICAL: If set to true, 'terraform destroy' will fail. 
  # Set to 'false' ONLY when you want to fully wipe your account.
  lifecycle {
    prevent_destroy = true
  }
}

# Versioning keeps a history of your state. 
# If your state file gets corrupted, you can roll back to a previous version.
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption ensures that sensitive data (like DB passwords in your state) 
# is encrypted at rest in the S3 bucket.
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Security best practice: Prevents your state file from ever being public
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# DYNAMODB: THE "CONCURRENCY LOCK"
# Prevents two users from running 'terraform apply' at the same time
# ------------------------------------------------------------------------------

resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-lock"
  
  # Pay only for what you use (Free Tier friendly)
  billing_mode = "PAY_PER_REQUEST"
  
  # The attribute 'LockID' is required by Terraform for state locking
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S" # String type
  }
}
