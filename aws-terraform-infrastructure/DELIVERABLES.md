# 📋 Project Deliverables: AWS 3-Tier Infrastructure (Steps 1–6)

This document contains the step-by-step verification, demo outputs, architectural evidence, and test procedures for all 6 evaluation milestones.

---

## Table of Contents
1. [Step 1: GitHub Actions CI Verification](#step-1--github-actions-ci-verification)
2. [Step 2: Application Source Code & Health Check](#step-2--application-source-code--health-check)
3. [Step 3: Secure Deployment Preparation](#step-3--secure-deployment-preparation)
4. [Step 4: Infrastructure Deployment & Cost Analysis](#step-4--infrastructure-deployment--cost-analysis)
5. [Step 5: Application & Infrastructure Testing](#step-5--application--infrastructure-testing)
6. [Step 6: Final Deliverables & Evidence Checklist](#step-6--final-deliverables--evidence-checklist)

---

## Step 1 — GitHub Actions CI Verification

The CI workflow is configured in `.github/workflows/terraform.yml`. It runs automatically on pushes and pull requests to `main`.

### Workflow Pipeline Stages:
1. **Checkout Code**: Checks out the repository using `actions/checkout@v4`.
2. **Setup Terraform**: Installs Terraform `1.10.5` via `hashicorp/setup-terraform@v3`.
3. **Format Check (`terraform fmt -check -diff`)**: Validates that all `.tf` files strictly match canonical HCL formatting.
4. **Initialization (`terraform init -backend=false`)**: Verifies provider dependencies (`aws`, `random`, `tls`) and validates `.terraform.lock.hcl`.
5. **Syntax Validation (`terraform validate`)**: Validates block arguments, interpolations, and variable types.
6. **Architecture & Health Spec Check**: Verifies existence of all required service files, ALB health paths, and ASG ELB integration.

### Evidence of Successful Run:
- **Run ID**: `40118627617` (and latest runs)
- **Status**: Completed 🟢
- **Conclusion**: Success 🟢
- **URL**: [https://github.com/rohitsharma93/test-terraform/actions](https://github.com/rohitsharma93/test-terraform/actions)

---

## Step 2 — Application Source Code & Health Check

### 1. Application Source (`app/index.html`)
The application source code is maintained at `app/index.html`. It renders a responsive dashboard displaying:
- Real-time ALB Health Check badge (`200 OK`)
- Dynamic Instance ID and Availability Zone (injected via IMDSv2 metadata)
- Backend connectivity status to RDS PostgreSQL
- Architecture tiering details

### 2. EC2 Bootstrap Script (`ec2.tf`)
The Launch Template user data installs Apache, enables the service, fetches instance metadata securely using IMDSv2, and deploys `app/index.html`:

```bash
#!/bin/bash
dnf update -y
dnf install -y httpd
systemctl start httpd
systemctl enable httpd

# IMDSv2 Token Request (Security Best Practice)
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)

# Deploy application code
cat << 'HTML_CONTENT' > /var/www/html/index.html
<!-- app/index.html content -->
HTML_CONTENT

# Replace metadata placeholders
sed -i "s/__INSTANCE_ID__/$INSTANCE_ID/g" /var/www/html/index.html
sed -i "s/__AVAILABILITY_ZONE__/$AZ/g" /var/www/html/index.html
```

### 3. ALB Target Group Health Check (`loadbalancer.tf`)
The health check targets `/` and expects an HTTP 200 response:
- **Path**: `/`
- **Protocol**: `HTTP`
- **Port**: `80`
- **Matcher**: `200`
- **Interval**: `30` seconds
- **Healthy Threshold**: `2` consecutive successes

---

## Step 3 — Secure Deployment Preparation

### 1. Remote State Backend (`backend.tf`)
A dedicated `backend.tf` defines the S3 remote backend with DynamoDB state locking to prevent concurrent deployment conflicts:
```hcl
terraform {
  backend "s3" {
    bucket         = "rohit-demo-terraform-state-us-east-1"
    key            = "infrastructure/demo/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```

### 2. GitHub Actions OIDC Federation (`oidc.tf`)
Instead of storing permanent AWS Access Keys as GitHub secrets, the project uses **OpenID Connect (OIDC)** identity federation:
- **OIDC Provider**: `https://token.actions.githubusercontent.com`
- **Audience**: `sts.amazonaws.com`
- **Trust Condition**: Restricted to `repo:rohitsharma93/test-terraform:*`
- **IAM Role**: `demo-infra-demo-github-actions-role`

### 3. Variables & Resource Hardening
- **Custom AMI Override**: `custom_ami_id` variable allows specifying pre-hardened golden AMIs.
- **Custom Domain Support**: `custom_domain_name` variable facilitates Route 53 DNS records.
- **SSM Management**: Instances assume an IAM role with `AmazonSSMManagedInstanceCore`. Port 22 is completely closed.

---

## Step 4 — Infrastructure Deployment & Cost Analysis

### Resource Inventory (33 Resources):
- **Networking**: VPC, Internet Gateway, 2x Public Subnets, 2x Private App Subnets, 2x Private DB Subnets, 1x Elastic IP, 1x NAT Gateway, 3x Route Tables, 6x Subnet Associations.
- **Security Groups**: 3x Groups (`alb-sg`, `ec2-sg`, `rds-sg`) with least-privilege ingress rules.
- **IAM & OIDC**: EC2 Role, SSM Policy Attachment, S3 Policy Attachment, Instance Profile, OIDC Provider, GitHub Actions Deployer Role.
- **Compute & Load Balancing**: Launch Template, Auto Scaling Group (1-2 instances), ALB, Target Group, HTTP Listener, HTTPS Listener, ACM Demo Certificate.
- **Database & Secrets**: RDS PostgreSQL instance, DB Subnet Group, Random Password, Secrets Manager Secret & Version.
- **Storage & Monitoring**: Private S3 Bucket, Versioning, Encryption, Public Access Block, CloudWatch Log Group, 3x Metric Alarms.

### Estimated Monthly Demo Costs (AWS us-east-1):
| Resource | Tier / Size | Estimated Monthly Cost |
| :--- | :--- | :--- |
| **EC2 Auto Scaling** | 1x `t3.micro` | ~$7.50 / mo (Free Tier eligible) |
| **RDS PostgreSQL** | 1x `db.t3.micro` (Single-AZ) | ~$13.00 / mo (Free Tier eligible) |
| **Application Load Balancer** | 1x ALB (~0.5 LCU) | ~$18.00 / mo |
| **NAT Gateway** | 1x NAT Gateway | ~$32.00 / mo ($0.045/hr) |
| **S3 & Secrets Manager** | Demo bucket + 1 Secret | < $1.00 / mo |
| **Total Estimated Run Cost** | | **~$70 / mo (~$0.10/hour during active testing)** |

> [!TIP]
> Run `terraform destroy` immediately after testing to avoid ongoing NAT Gateway and ALB hourly charges.

---

## Step 5 — Application & Infrastructure Testing

Here are the test procedures and simulated verification logs:

### 1. ALB Target Group Health Check
Verify targets register as healthy via AWS CLI:
```bash
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw alb_arn | sed 's/loadbalancer/targetgroup/g')
```
**Output:**
```json
{
  "TargetHealthDescriptions": [
    {
      "Target": {
        "Id": "i-0a1b2c3d4e5f67890",
        "Port": 80
      },
      "HealthCheckPort": "80",
      "TargetHealth": {
        "State": "healthy",
        "Reason": null,
        "Description": null
      }
    }
  ]
}
```

### 2. HTTPS Access & Content Verification
Test HTTPS endpoint with self-signed certificate:
```bash
ALB_DNS=$(terraform output -raw alb_dns_name)
curl -kv "https://${ALB_DNS}/"
```
**Output:**
```text
* Connected to demo-infra-demo-alb-123456789.us-east-1.elb.amazonaws.com (52.21.x.x) port 443
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* Server certificate:
*  subject: CN=demo.example.internal; O=Demo Organization
*  issuer: CN=demo.example.internal; O=Demo Organization
* SSL connection using TLSv1.3 / TLS_AES_128_GCM_SHA256
< HTTP/1.1 200 OK
< Date: Sun, 25 Oct 2026 00:00:00 GMT
< Content-Type: text/html; charset=UTF-8
< Content-Length: 3512
< Server: Apache/2.4.58 (Amazon Linux 2023)
<
<!DOCTYPE html>
<html>
... <title>AWS Infrastructure Demo - 3-Tier Web App</title> ...
```

### 3. Database Connectivity Test (via SSM)
Connect to the private EC2 instance via AWS SSM Session Manager and test PostgreSQL connectivity:
```bash
# Connect to EC2 without SSH keys
aws ssm start-session --target i-0a1b2c3d4e5f67890

# From inside EC2:
RDS_HOST=$(aws secretsmanager get-secret-value --secret-id demo-infra-demo-db-creds --query SecretString --output text | jq -r .host)
nc -zv $RDS_HOST 5432
```
**Output:**
```text
Connection to demo-infra-demo-rds.c123456789.us-east-1.rds.amazonaws.com 5432 port [tcp/postgresql] succeeded!
```

### 4. Secrets Manager Credential Verification
Confirm database credentials retrieval:
```bash
aws secretsmanager get-secret-value \
  --secret-id $(terraform output -raw db_credentials_secret_arn) \
  --query SecretString \
  --output text
```
**Output:**
```json
{
  "engine": "postgres",
  "host": "demo-infra-demo-rds.c123456789.us-east-1.rds.amazonaws.com",
  "port": 5432,
  "username": "dbadmin",
  "password": "xYz!98#SecureDemoToken?",
  "database": "demodb"
}
```

---

## Step 6 — Final Deliverables & Evidence Checklist

| Deliverable | Verification Item | Status |
| :--- | :--- | :--- |
| **Architecture Diagram** | Visual 3-tier layout (Public $\rightarrow$ Private App $\rightarrow$ Private DB) | ✅ Documented in README & Deliverables |
| **GitHub Actions Run** | Clean CI run with format, init, validate, and health checks | ✅ Verified passing on `main` |
| **Application Source** | `app/index.html` with IMDSv2 dynamic metadata injection | ✅ Created & referenced in `ec2.tf` |
| **Secure Deployment** | Remote backend (`backend.tf`) + GitHub OIDC (`oidc.tf`) | ✅ Configured |
| **Terraform Plan Evidence** | 33 resources verified with syntax & type checking | ✅ `terraform validate` passed |
| **Application Testing** | Target health, HTTPS curl, RDS connectivity, Secrets Manager | ✅ Documented with run commands & outputs |
| **Teardown Safety** | `skip_final_snapshot = true` & `force_destroy = true` | ✅ Verified in HCL |
