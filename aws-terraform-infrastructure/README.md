# ☁️ AWS Terraform Demo Infrastructure

A modular, production-pattern Terraform infrastructure blueprint designed for demonstration, learning, and architecture reference.

> [!NOTE]
> This configuration is intended as a **demo / reference architecture** and includes demo-friendly defaults (such as single NAT Gateway, `skip_final_snapshot = true` for RDS, `force_destroy = true` for S3, and self-signed TLS via ACM).

---

## 🏛️ Architecture Overview

```mermaid
flowchart TD
    Internet([Public Internet / Users]) -->|HTTP / HTTPS| ALB[Application Load Balancer]

    subgraph VPC ["AWS VPC (10.0.0.0/16)"]
        subgraph PublicSubnets ["Public Subnets (AZ-a & AZ-b)"]
            ALB
            NAT[NAT Gateway]
            IGW[Internet Gateway]
        end

        subgraph PrivateAppSubnets ["Private App Subnets (AZ-a & AZ-b)"]
            ASG[Auto Scaling Group\nEC2 Instances + Web App]
        end

        subgraph PrivateDBSubnets ["Private DB Subnets (AZ-a & AZ-b)"]
            RDS[(Amazon RDS\nPostgreSQL)]
        end
    end

    Internet <--> IGW
    IGW <--> ALB
    ALB -->|Port 80 (Internal)| ASG
    ASG -->|Port 5432| RDS
    ASG -->|Egress via NAT| NAT
    NAT --> IGW

    subgraph SupportingServices ["Supporting Cloud Services"]
        S3[Amazon S3\nEncrypted Storage Bucket]
        SM[AWS Secrets Manager\nDB Master Credentials]
        CW[Amazon CloudWatch\nLogs & Alarms]
        ACM[AWS Certificate Manager\nDemo TLS Certificate]
        IAM[AWS IAM Role\nSSM & S3 Policies]
    end

    ASG -.->|Assume Role| IAM
    IAM -.->|Access| S3
    SM -.->|Provides Password| RDS
    ALB -.->|SSL/TLS Cert| ACM
    ASG -.->|Logs & Metrics| CW
```

---

## 📂 File Directory Structure

```text
aws-terraform-infrastructure/
├── provider.tf             # AWS provider declaration and default tags
├── versions.tf             # Required Terraform & provider versions
├── variables.tf            # Input variables with types and defaults
├── locals.tf               # Local naming conventions and resource tags
├── vpc.tf                  # Main AWS VPC configuration
├── subnets.tf              # Public, Private App, and Private DB subnets + DB Subnet Group
├── internet_gateway.tf     # Internet Gateway for public traffic
├── nat_gateway.tf          # Elastic IP and NAT Gateway for private egress
├── route_tables.tf         # Route tables, routes, and subnet associations
├── security_groups.tf      # Multi-tier Security Groups (ALB, EC2, RDS)
├── iam.tf                  # EC2 IAM Role, Instance Profile, and S3/SSM policies
├── acm.tf                  # Demo TLS Certificate generation and ACM registration
├── loadbalancer.tf         # Application Load Balancer, Listeners, Target Group
├── ec2.tf                  # Launch Template and Auto Scaling Group
├── rds.tf                  # RDS PostgreSQL database instance
├── secrets_manager.tf      # Secrets Manager secret for DB password generation
├── s3.tf                   # Private S3 bucket with encryption and public access block
├── monitoring.tf           # CloudWatch Log Group and threshold alarms
├── outputs.tf              # Structured outputs for VPC, ALB, RDS, S3, etc.
├── terraform.tfvars.example# Example input variables file
├── .gitignore              # Ignores local state, secrets, and cache
├── README.md               # Architecture documentation and usage guide
└── .github/
    └── workflows/
        └── terraform.yml   # GitHub Actions validation & linting CI pipeline
```

---

## 🛠️ Included AWS Services

| Service | Component Description |
| :--- | :--- |
| **VPC & Networking** | VPC (`10.0.0.0/16`), 2 Public Subnets, 2 Private App Subnets, 2 Private DB Subnets, Internet Gateway, Single NAT Gateway (demo cost saver). |
| **Security Groups** | Tiered isolation: Internet -> ALB only -> EC2 only -> RDS only. No public database or instance exposure. |
| **IAM** | IAM Instance Profile for EC2 with `AmazonSSMManagedInstanceCore` (no bastion host or SSH key pairs required) and S3 scoped permissions. |
| **Compute** | Auto Scaling Group (min: 1, max: 2) with Launch Template (Amazon Linux 2023) and bootstrap Apache demo page. |
| **Load Balancer** | Internet-facing Application Load Balancer with HTTP (port 80) and HTTPS (port 443) listeners forwarding to Target Group. |
| **ACM** | TLS Certificate created via Terraform `tls` provider and imported into ACM for immediate local HTTPS testing. |
| **Database** | Amazon RDS PostgreSQL `15.4` on `db.t3.micro` residing in an isolated private DB subnet tier. |
| **Secrets Manager** | Generates an automated 20-character database password with `random_password` and stores connection parameters. |
| **Storage (S3)** | Encrypted S3 bucket with versioning enabled, public access blocked, and `force_destroy = true` for easy demo teardown. |
| **Monitoring** | CloudWatch Log Group for application logs, plus CloudWatch Alarms for ASG High CPU, ALB 5XX error rates, and RDS free storage space. |

---

## 🚀 Quick Start Guide

### 1. Prerequisites
- [Terraform](https://developer.hashicorp.com/terraform/downloads) `>= 1.5.0`
- [AWS CLI](https://aws.amazon.com/cli/) configured with proper credentials (`aws configure`)

### 2. Initialize Terraform
Navigate to the directory and initialize providers:
```bash
cd aws-terraform-infrastructure
terraform init
```

### 3. Review Configuration
Copy the example variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```
*(Optional)* Customize region, instance sizes, or CIDR blocks in `terraform.tfvars`.

### 4. Validate and Plan
```bash
# Check formatting
terraform fmt -check

# Validate configuration syntax
terraform validate

# Review execution plan
terraform plan
```

### 5. Apply (Demo Provisioning)
```bash
terraform apply
```

### 6. Verify Deployment
Once applied, Terraform prints the output values:
- `alb_dns_name`: Open in browser `http://<ALB-DNS-NAME>` to view the demo page.
- `secrets_manager_secret_arn`: ARN of the generated database credentials.
- `rds_endpoint`: PostgreSQL endpoint address.

---

## 🧹 Cleanup / Destroy

To prevent unexpected AWS charges when finished exploring the demo:
```bash
terraform destroy -auto-approve
```

All resources have been configured with demo cleanup in mind:
- S3 bucket has `force_destroy = true`
- RDS instance has `skip_final_snapshot = true` and `deletion_protection = false`
- Secrets Manager has `recovery_window_in_days = 0`
