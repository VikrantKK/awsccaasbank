# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Awsccaasbank CCaaS (Contact Center as a Service) Terraform blueprint deploying AWS Amazon Connect infrastructure. Australian bank — all resources must stay in **ap-southeast-2** for APRA CPS 234 compliance.

## Build & Deploy Commands

```bash
# Bootstrap remote state (one-time per environment)
./scripts/bootstrap-backend.sh <env>

# Deploy an environment
cd environments/<env>
terraform init -backend-config=../../backends/<env>.s3.tfbackend
terraform plan -out=tfplan
terraform apply tfplan

# Format all Terraform
terraform fmt -recursive

# Lint
tflint --init && tflint --recursive

# Security scan
checkov -d . --framework terraform

# Validate deployment
python scripts/validate_readiness.py --environment <env>
```

Environments: `dev`, `test`, `qa`, `staging`, `prod`

## Architecture

### Module Dependency Graph

```
security → networking → storage → lambda → lex → connect → routing → monitoring
                                                     ↑
                                          security_guardrails (independent)
```

Each environment (`environments/<env>/main.tf`) composes all modules. Modules pass data via outputs:
- **security** exports KMS key ARNs and IAM role ARNs (consumed by all)
- **networking** exports VPC/subnet IDs and security group IDs (consumed by lambda)
- **storage** exports S3 bucket ARNs/IDs and DynamoDB table ARNs/names (consumed by connect, lambda, security)
- **lambda** exports function ARNs (consumed by connect for associations)
- **lex** exports bot alias ARN (consumed by connect for bot association)
- **connect** exports instance ID and contact flow IDs (consumed by routing, monitoring)
- **routing** exports queue IDs/ARNs (consumed by monitoring)
- **security_guardrails** is independent — AWS Config rules, CloudTrail, S3 account-level public access block

### Key Patterns

- **State isolation**: Directory-based (not workspaces). Each env has its own S3 backend key.
- **Encryption**: 4 separate KMS CMKs (connect, storage, dynamodb, logs) with distinct rotation/access policies.
- **IAM**: Per-function Lambda roles (not shared). All policies use `aws:RequestedRegion` condition locked to ap-southeast-2.
- **Kinesis**: CTR and agent event streams in `modules/connect/kinesis.tf`. Firehose delivers CTR to S3.
- **Contact flows**: JSON files in `contact_flows/` loaded via `file()` in the connect module.
- **VPC endpoints**: Gateway (S3, DynamoDB) + Interface (KMS, Logs, STS, Voice ID, Kinesis) in networking module.

## Naming Conventions

- Resources: `${var.project_name}-${var.environment}-<purpose>` (e.g., `awsccaasbank-ccaas-dev-recordings`)
- KMS aliases: `alias/awsccaasbank-ccaas-{env}-{purpose}`
- Lambda functions: `${project_name}-${environment}-{function_name}`
- S3 buckets: `${project_name}-${environment}-{purpose}-${account_id}`

## Compliance Constraints

- **Region lock**: ap-southeast-2 only. Never add cross-region replication for PII/recordings.
- **KMS**: All data at rest must use customer-managed keys. No AWS-managed or SSE-S3.
- **S3**: All buckets must block public access, enforce SSL, enable versioning.
- **IAM**: No wildcard `*` actions. No inline policies (use managed).
- **Logging**: CloudTrail enabled, VPC Flow Logs enabled, all log groups KMS-encrypted.
- **Tags**: All resources must have: Project, Environment, Owner, CostCenter, DataClassification, ManagedBy.

## CI/CD

Single pipeline in `.github/workflows/deploy.yml`:
- PR: format check → TFLint → Checkov → plan (all envs)
- Merge to main: sequential apply `dev → test → qa → staging → prod`
- Prod requires manual approval via GitHub environment protection rules
- AWS auth via OIDC federation (no long-lived keys)

## When Adding a New Module

1. Create `modules/<name>/` with: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`
2. Wire it into each `environments/<env>/main.tf`
3. Ensure all resources use KMS encryption from the security module
4. Add mandatory tags via `var.tags` + merge pattern
5. Run `terraform fmt -recursive` and `checkov -d .`
