# ==============================================================================
# Terraform Outputs
# ==============================================================================

# --- Networking Outputs ---
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "IDs of the private application subnets"
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  description = "IDs of the private database subnets"
  value       = aws_subnet.private_db[*].id
}

# --- Load Balancer Outputs ---
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Canonical hosted zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

# --- Compute Outputs ---
output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

output "launch_template_id" {
  description = "ID of the EC2 Launch Template"
  value       = aws_launch_template.main.id
}

output "ec2_security_group_id" {
  description = "Security Group ID for application EC2 instances"
  value       = aws_security_group.ec2.id
}

# --- Database Outputs ---
output "rds_endpoint" {
  description = "Connection endpoint for the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "Hostname of the RDS instance"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "Port the RDS database is listening on"
  value       = aws_db_instance.main.port
}

output "rds_database_name" {
  description = "Name of the default RDS database"
  value       = aws_db_instance.main.db_name
}

# --- Secrets Manager Outputs ---
output "db_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret storing DB credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

# --- Storage Outputs ---
output "s3_bucket_name" {
  description = "Name of the demo S3 storage bucket"
  value       = aws_s3_bucket.demo_bucket.id
}

output "s3_bucket_arn" {
  description = "ARN of the demo S3 storage bucket"
  value       = aws_s3_bucket.demo_bucket.arn
}

# --- Monitoring & Security Outputs ---
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for applications"
  value       = aws_cloudwatch_log_group.app.name
}

output "acm_certificate_arn" {
  description = "ARN of the demo ACM TLS certificate"
  value       = aws_acm_certificate.demo.arn
}
