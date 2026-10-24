# AWS Terraform Demo Infrastructure

A clean, modular Terraform setup for deploying a classic 3-tier web architecture on AWS. 

This project is built as a hands-on reference to demonstrate how core AWS networking, compute, database, and monitoring services connect together in code—without exposing sensitive resources to the public internet.

> 📘 **Project Deliverables**: For the complete Step 1–6 evaluation evidence, test results, simulated deployment logs, and cost analysis, see [DELIVERABLES.md](./DELIVERABLES.md).

---

## How the Architecture Works

The stack follows the standard 3-tier pattern (Public $\rightarrow$ Private App $\rightarrow$ Private Database):

```
       Internet
          │
          ▼
   [Internet Gateway]
          │
┌─────────▼────────────────────────────────────────┐
│ Public Subnets                                   │
│  ├── Application Load Balancer (ALB)             │
│  └── NAT Gateway (Outbound traffic only)         │
└─────────┬────────────────────────────────────────┘
          │ (Forward HTTP/HTTPS)
┌─────────▼────────────────────────────────────────┐
│ Private Application Subnets                      │
│  └── Auto Scaling Group (EC2 Instances)          │
│      - Runs Amazon Linux 2023 + Apache           │
│      - Managed via AWS Systems Manager (no SSH)  │
└─────────┬────────────────────────────────────────┘
          │ (Internal port 5432)
┌─────────▼────────────────────────────────────────┐
│ Private Database Subnets                         │
│  └── RDS PostgreSQL Instance                     │
│      - Only accepts connections from EC2 SG      │
│      - Master password generated in Secrets Mgr  │
└──────────────────────────────────────────────────┘
```

### The Pieces in Plain English:

1. **VPC & Subnets**: A single VPC (`10.0.0.0/16`) split across 2 Availability Zones with 6 subnets total (2 public, 2 private app, 2 private database).
2. **Public Entry Point**: The Application Load Balancer receives external web traffic. A single NAT Gateway lets private instances download OS patches without accepting inbound connections from the web.
3. **App Servers (EC2 & ASG)**: EC2 instances run in private subnets inside an Auto Scaling Group. They never get public IPs. Instead of exposing port 22 or managing SSH key pairs, instances use an IAM role with AWS Systems Manager (SSM) Session Manager.
4. **Database (RDS & Secrets Manager)**: An RDS PostgreSQL instance sits in dedicated database subnets. The master password is generated with Terraform's `random_password` and saved directly into AWS Secrets Manager so no passwords are hardcoded in plain text.
5. **Storage & SSL**: A private S3 bucket handles object storage with versioning and encryption. A demo TLS certificate is generated and loaded into AWS Certificate Manager (ACM) to enable HTTPS on the ALB without needing a custom domain.
6. **Monitoring**: CloudWatch log groups collect server logs, with automated alarms set up for high CPU, ALB 5xx errors, and low database storage.

---

## Repository Structure

All Terraform code is organized inside [`aws-terraform-infrastructure/`](./aws-terraform-infrastructure/):

| File | What it does |
| :--- | :--- |
| `vpc.tf` | Creates the VPC with DNS support and hostnames enabled. |
| `subnets.tf` | Sets up public, application, and database subnets across 2 AZs. |
| `internet_gateway.tf` | Attaches the internet gateway to allow public ALB traffic. |
| `nat_gateway.tf` | Provisions an Elastic IP and NAT gateway for private subnet internet access. |
| `route_tables.tf` | Configures routing tables and associates them with each subnet tier. |
| `security_groups.tf` | Strict firewall rules: ALB allows 80/443; EC2 allows only ALB; RDS allows only EC2. |
| `iam.tf` | IAM role and instance profile for EC2 (SSM managed policy + S3 bucket access). |
| `acm.tf` | Generates a self-signed TLS cert and registers it in ACM for HTTPS demo testing. |
| `loadbalancer.tf` | Creates the ALB, target group, health checks, and HTTP/HTTPS listeners. |
| `ec2.tf` | Launch template (Amazon Linux 2023) and Auto Scaling Group with health checks. |
| `rds.tf` | RDS PostgreSQL database instance configured in the private DB subnet group. |
| `secrets_manager.tf` | Generates a random master password and saves DB credentials in Secrets Manager. |
| `s3.tf` | S3 bucket with default server-side encryption, versioning, and public access blocked. |
| `monitoring.tf` | CloudWatch log group and alarms for EC2 CPU, ALB errors, and RDS storage. |
| `variables.tf` | Input variable declarations with defaults. |
| `locals.tf` | Common tags and resource naming conventions. |
| `outputs.tf` | Useful outputs (ALB DNS name, DB endpoint, secret ARN, bucket name). |
| `provider.tf` & `versions.tf` | AWS provider configuration and version constraints. |
| `terraform.tfvars.example` | Example variable values ready to copy into `terraform.tfvars`. |
| `.github/workflows/terraform.yml` | GitHub Actions CI workflow to validate syntax and test health checks. |

---

## Getting Started

### Prerequisites
- [Terraform](https://developer.hashicorp.com/terraform/downloads) (>= 1.5.0)
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured (`aws configure`)

### 1. Clone the repo and navigate to the Terraform folder
```bash
git clone https://github.com/rohitsharma93/test-terraform.git
cd test-terraform/aws-terraform-infrastructure
```

### 2. Prepare variables
Copy the example variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```
*(Optional)* Review `terraform.tfvars` if you want to change the AWS region (defaults to `us-east-1`) or instance types.

### 3. Initialize and Validate
```bash
# Download provider plugins
terraform init

# Check formatting and syntax
terraform fmt -check
terraform validate
```

### 4. Review the Plan and Deploy
```bash
# See what resources will be created
terraform plan

# Apply the infrastructure
terraform apply
```

Once deployment finishes, Terraform will output your ALB DNS name:
```bash
Outputs:
alb_dns_name = "demo-infra-demo-alb-xxxx.us-east-1.elb.amazonaws.com"
```
Open `http://<alb_dns_name>` in your browser to verify the Apache demo page is serving traffic.

---

## Tearing Down (Avoid AWS Costs)

When you are done testing, destroy the resources so you don't get charged for idle NAT Gateways or RDS instances:

```bash
terraform destroy
```

> **Note on Demo Settings**: To make destruction simple and avoid stuck resources during cleanup, `rds.tf` has `skip_final_snapshot = true` and `s3.tf` has `force_destroy = true`. Do not use these two settings on actual production databases or critical buckets.
