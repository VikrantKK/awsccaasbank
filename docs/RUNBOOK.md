# Operations Runbook — Awsccaasbank CCaaS Platform

## 1. Prerequisites
- Terraform >= 1.7.0
- AWS CLI v2 with credentials for target environment
- Python 3.12+ with boto3 (for validation)
- GitHub CLI (gh) authenticated
- Pre-commit installed

## 2. Initial Setup

### 2.1 Clone Repository
```bash
git clone https://github.com/VikrantKK/awsccaasbank-ccaas-blueprint.git
cd awsccaasbank-ccaas-blueprint
```

### 2.2 Install Pre-commit Hooks
```bash
pip install pre-commit
pre-commit install
```

### 2.3 Bootstrap Terraform State (one-time per environment)
```bash
chmod +x scripts/bootstrap-backend.sh
./scripts/bootstrap-backend.sh dev    # Creates S3 bucket + DynamoDB lock table
./scripts/bootstrap-backend.sh test
./scripts/bootstrap-backend.sh qa
./scripts/bootstrap-backend.sh staging
./scripts/bootstrap-backend.sh prod
```

## 3. Deployment Procedures

### 3.1 Deploy an Environment (Manual)
```bash
cd environments/<env>
terraform init -backend-config=../../backends/<env>.s3.tfbackend
terraform plan -out=tfplan
terraform apply tfplan
```

### 3.2 Deploy via CI/CD
1. Create a feature branch
2. Make changes
3. Push and open a PR — CI runs lint, Checkov, plan
4. Review plan output in PR comments
5. Merge to main — auto-deploys dev → test → qa → staging
6. Approve prod deployment in GitHub environment protection

### 3.3 Verify Deployment
```bash
# Check Connect instance
aws connect list-instances --region ap-southeast-2 \
  --query "InstanceSummaryList[?InstanceAlias=='awsccaasbank-ccaas-<env>']"

# Full readiness validation
pip install -r scripts/requirements.txt
python scripts/validate_readiness.py --environment <env>
```

## 4. Common Operations

### 4.1 Adding a New Queue
Edit `environments/<env>/terraform.tfvars` or pass queues variable:
```hcl
# In environments/<env>/main.tf or override via tfvars
module "routing" {
  queues = {
    new_queue = {
      description  = "New department queue"
      max_contacts = 20
      hours_type   = "standard_hours"
    }
  }
}
```

### 4.2 Adding a New Contact Flow
1. Design flow in Amazon Connect console
2. Export as JSON
3. Save to `contact_flows/<flow_name>.json`
4. Add `aws_connect_contact_flow` resource in `modules/connect/contact_flows.tf`
5. Deploy

### 4.3 Updating Lambda Functions
1. Edit source in `modules/lambda/src/<function_name>/index.py`
2. Deploy — Terraform detects source hash change and updates the function

### 4.4 Adding a Phone Number
```hcl
# In terraform.tfvars
phone_numbers = {
  main_line = {
    country_code = "AU"
    type         = "DID"
  }
}
```

## 5. Troubleshooting

### 5.1 State Lock Issues
```bash
# Check who holds the lock
aws dynamodb get-item \
  --table-name awsccaasbank-ccaas-terraform-locks-<env> \
  --key '{"LockID":{"S":"awsccaasbank-ccaas-terraform-state-<env>/ccaas/<env>/terraform.tfstate"}}' \
  --region ap-southeast-2
```

### 5.2 Terraform Plan Fails with Credential Error
- Verify AWS credentials: `aws sts get-caller-identity`
- For CI: check OIDC role ARN in GitHub secrets
- For local: ensure AWS CLI profile is configured for ap-southeast-2

### 5.3 Connect Instance Not Found in Validation
- Ensure Connect instance has been created (check Terraform output)
- Verify instance alias matches pattern: `awsccaasbank-ccaas-<env>`

## 6. Disaster Recovery

### 6.1 State Recovery
- S3 state bucket has versioning enabled — recover previous state version
- DynamoDB lock table protects against concurrent modifications

### 6.2 Infrastructure Recovery
```bash
cd environments/<env>
terraform init -backend-config=../../backends/<env>.s3.tfbackend
terraform plan    # Review drift
terraform apply   # Reconcile to desired state
```

### 6.3 Call Recording Recovery
- S3 versioning enabled on recordings bucket
- Lifecycle transitions to Glacier after configurable days
- Prod retention: 7 years (2555 days) for APRA compliance
