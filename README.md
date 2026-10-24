# test-terraform

Demo AWS Terraform infrastructure blueprint.

## Project Structure

- [`aws-terraform-infrastructure/`](./aws-terraform-infrastructure/): Complete multi-tier AWS demo infrastructure stack.
  - VPC, Subnets (Public, Private App, Private DB), IGW, NAT Gateway, Route Tables
  - Application Load Balancer (HTTP & HTTPS)
  - Auto Scaling Group & Launch Template (EC2)
  - RDS PostgreSQL Database with dynamic Secrets Manager credentials
  - Secure S3 storage bucket with versioning and encryption
  - CloudWatch Logs & Monitoring Alarms
  - IAM Roles & Instance Profiles with AWS Systems Manager Core support
  - Automated CI workflow via GitHub Actions

See [aws-terraform-infrastructure/README.md](./aws-terraform-infrastructure/README.md) for full architecture details and usage instructions.
