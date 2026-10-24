# AWS Terraform Infrastructure (Demo)

This folder contains the complete Terraform code for a 3-tier AWS architecture.

## Overview

The infrastructure creates an isolated environment where compute and database resources stay off the public internet:

```
[ Internet ] ──▶ [ Internet Gateway ] ──▶ [ ALB (Public Subnets) ]
                                                   │
                                      (Port 80 via Target Group)
                                                   ▼
                                        [ EC2 / ASG (Private App Subnets) ]
                                                   │
                                      (Port 5432 PostgreSQL)
                                                   ▼
                                        [ RDS DB (Private DB Subnets) ]
```

### Highlights:
- **No public SSH keys or open port 22**: EC2 instances run in private subnets and are accessible through AWS Systems Manager Session Manager.
- **Dynamic secrets**: The database password is generated randomly by Terraform and stored in AWS Secrets Manager.
- **NAT for outbound updates**: Private instances can reach the internet for updates through a single NAT Gateway without being exposed to incoming traffic.
- **Demo-safe teardown**: S3 bucket has `force_destroy = true` and RDS has `skip_final_snapshot = true` so `terraform destroy` cleanly removes everything without hanging.

---

## Usage

```bash
# 1. Set up variables
cp terraform.tfvars.example terraform.tfvars

# 2. Initialize
terraform init

# 3. Plan & Apply
terraform plan
terraform apply

# 4. Clean up when finished
terraform destroy
```

See the root [`../README.md`](../README.md) for full architecture notes and file breakdowns.
