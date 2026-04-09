# ------------------------------------------------------------------------------
# S3 BUCKET OUTPUTS
# ------------------------------------------------------------------------------

# CRITICAL: This is used by manage.sh to dynamically create the backend.conf file
output "s3_bucket_name" {
  value       = aws_s3_bucket.terraform_state.id
  description = "The unique ID/Name of the S3 bucket used for state storage"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "The Amazon Resource Name of the S3 bucket"
}

output "s3_bucket_region" {
  # Useful for verifying that the bucket was created in the correct region (us-west-2)
  value       = aws_s3_bucket.terraform_state.region
  description = "The AWS region where the S3 bucket resides"
}

# Verification output: Ensures our 'Undo' button (versioning) is active
output "s3_bucket_versioning_status" {
  value       = aws_s3_bucket_versioning.enabled.versioning_configuration[0].status
  description = "Status of S3 versioning (should be 'Enabled')"
}

# ------------------------------------------------------------------------------
# DYNAMODB TABLE OUTPUTS
# ------------------------------------------------------------------------------

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_lock.name
  description = "The name of the DynamoDB table used for state locking"
}

output "dynamodb_table_arn" {
  value       = aws_dynamodb_table.terraform_lock.arn
  description = "The ARN of the DynamoDB table"
}

# ------------------------------------------------------------------------------
# BACKEND CONFIGURATION HELPER
# ------------------------------------------------------------------------------
# This generates a 'cheat sheet' in your terminal after you run ./manage.sh deploy
output "backend_config_guide" {
  value = <<EOF
  backend "s3" {
    bucket         = "${aws_s3_bucket.terraform_state.id}"
    key            = "projects/ec2-demo/terraform.tfstate"
    region         = "${aws_s3_bucket.terraform_state.region}"
    dynamodb_table = "${aws_dynamodb_table.terraform_lock.name}"
    encrypt        = true
  }
EOF
  description = "A reference block for manual configuration if needed"
}
