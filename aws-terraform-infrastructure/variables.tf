variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project identifier used in resource names and tags"
  type        = string
  default     = "demo-infra"
}

variable "environment" {
  description = "Target deployment environment"
  type        = string
  default     = "demo"
}

# --- Network Configuration ---
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of Availability Zones to deploy subnets in"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private application subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for private database subnets"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "enable_nat_gateway" {
  description = "Toggle NAT Gateway creation for private subnets outbound internet access"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Deploy a single NAT Gateway across all AZs to save demo costs"
  type        = bool
  default     = true
}

# --- Compute Configuration ---
variable "ec2_instance_type" {
  description = "EC2 instance size for the Auto Scaling Group"
  type        = string
  default     = "t3.micro"
}

variable "custom_ami_id" {
  description = "Specific AMI ID to override automated Amazon Linux 2023 lookup"
  type        = string
  default     = ""
}

variable "asg_min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 2
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in the ASG"
  type        = number
  default     = 1
}

# --- Database Configuration ---
variable "db_engine" {
  description = "RDS database engine"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "RDS engine version"
  type        = string
  default     = "15.4"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in gigabytes for RDS"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "demodb"
}

variable "db_username" {
  description = "Master username for the RDS database"
  type        = string
  default     = "dbadmin"
}

# --- Domain & TLS Configuration ---
variable "demo_domain_name" {
  description = "Domain name for self-signed demo ACM certificate"
  type        = string
  default     = "demo.example.internal"
}

variable "custom_domain_name" {
  description = "User-controlled public domain name (optional, Route 53 managed)"
  type        = string
  default     = ""
}

# --- GitHub OIDC Configuration ---
variable "github_repository" {
  description = "GitHub repository path in owner/repo format for OIDC federation"
  type        = string
  default     = "rohitsharma93/test-terraform"
}
