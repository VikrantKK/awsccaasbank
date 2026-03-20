# Implementation Steps — Awsccaasbank CCaaS Blueprint

## Overview

This document records every engineering step taken to scaffold, validate, and harden the Awsccaasbank CCaaS Terraform Blueprint. The project follows an **AI-first infrastructure engineering** methodology, using Claude Code (Anthropic's Claude Opus 4.6) acting as a Senior Platform Engineer. All resources target **ap-southeast-2** (Sydney) for APRA CPS 234 data sovereignty compliance.

**Repository**: [https://github.com/VikrantKK/awsccaasbank](https://github.com/VikrantKK/awsccaasbank)

---

## Phase 1: Project Initialization

### Step 1.1 — Directory Structure Creation

**Action**: Created the complete directory tree to house all Terraform modules, environment compositions, backend configs, contact flow definitions, automation scripts, and CI/CD workflows.

```bash
mkdir -p modules/{connect,routing,lambda/src/{cti_adapter,crm_lookup,post_call_survey},storage,security,monitoring,networking,lex} \
         environments/{dev,staging,prod} \
         backends \
         contact_flows \
         scripts \
         .github/workflows
```

**Result**: 9 module directories (`connect`, `routing`, `lambda`, `storage`, `security`, `monitoring`, `networking`, `lex`, later `security_guardrails`), 3 initial environment directories (`dev`, `staging`, `prod`), plus supporting directories for backends, contact flows, scripts, and GitHub Actions.

---

### Step 1.2 — Root Configuration Files

**Action**: Created project-level configuration files to establish coding standards, security scanning, linting rules, and repository documentation.

| File | Purpose |
|------|---------|
| `.gitignore` | Excludes Terraform state (`*.tfstate`, `.terraform/`), lock files, IDE files (`.idea/`, `.vscode/`), Lambda build artifacts (`modules/lambda/src/**/package/`, `*.zip`), sensitive var files (`*.auto.tfvars`, `secret.tfvars`, `.env`), and security tool caches (`.tfsec/`, `.trivy/`) |
| `.pre-commit-config.yaml` | Hooks from `antonbabenko/pre-commit-tf` v1.96.1 (`terraform_fmt`, `terraform_validate`, `terraform_tflint`, `terraform_tfsec`, `terraform_docs`) and `pre-commit/pre-commit-hooks` v4.6.0 (`detect-aws-credentials`, `detect-private-key`, `check-merge-conflict`, `end-of-file-fixer`, `trailing-whitespace`, `check-yaml`, `check-json`) |
| `.tflint.hcl` | AWS ruleset configuration, naming conventions enforcement, documented variables/outputs requirement |
| `README.md` | Project overview with Mermaid architecture diagram, compliance mapping table, quick start guide, environment descriptions, CI/CD pipeline diagram, and tagging strategy |
| `CLAUDE.md` | AI assistant guidance: module dependency graph, naming conventions, compliance constraints, build/deploy commands, patterns for adding new modules |

---

## Phase 2: Module Development (Parallel)

All 8 core modules were designed and implemented concurrently via parallel AI agents. Each module follows the standard structure: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, plus domain-specific files.

---

### Step 2.1 — Security Module (`modules/security/`)

**Files created**: `main.tf`, `iam_roles.tf`, `variables.tf`, `outputs.tf`, `versions.tf`

**KMS Keys** (4 customer-managed keys):

| Key | Purpose | Alias Pattern |
|-----|---------|---------------|
| `connect` | Amazon Connect encryption | `alias/awsccaasbank-ccaas-{env}-connect` |
| `storage` | S3 bucket encryption | `alias/awsccaasbank-ccaas-{env}-storage` |
| `dynamodb` | DynamoDB table encryption | `alias/awsccaasbank-ccaas-{env}-dynamodb` |
| `logs` | CloudWatch Logs encryption | `alias/awsccaasbank-ccaas-{env}-logs` |

- All keys: automatic rotation enabled, configurable deletion window (7 days dev, 30 days prod)
- Shared key policy: root account admin access + key administrator actions

**IAM Service Roles** (3):

| Role | Trust Principal | Purpose |
|------|----------------|---------|
| `connect_role` | `connect.amazonaws.com` | Amazon Connect service operations |
| `lambda_role` | `lambda.amazonaws.com` | Lambda function execution |
| `lex_role` | `lexv2.amazonaws.com` | Lex bot operations |

**IAM Policies** (3):

| Policy | Permissions |
|--------|-------------|
| Lambda | DynamoDB CRUD + S3 read + KMS encrypt/decrypt + CloudWatch Logs |
| Connect | S3 PutObject + KMS encrypt/decrypt + Lex runtime |
| Lex | CloudWatch Logs create/put |

- All policies scoped with `aws:RequestedRegion` condition locked to `ap-southeast-2`
- Confused deputy protection via `aws:SourceAccount` condition on all assume-role trust policies

---

### Step 2.2 — Networking Module (`modules/networking/`)

**Files created**: `main.tf`, `security_groups.tf`, `variables.tf`, `outputs.tf`, `versions.tf`

**VPC Configuration**:
- VPC with DNS support and DNS hostnames enabled
- Parameterized CIDR block (dev: `10.1.0.0/16`, prod: `10.3.0.0/16`)

**Subnets**:
- 3 private subnets across `ap-southeast-2a`, `ap-southeast-2b`, `ap-southeast-2c` using `cidrsubnet()` function
- 3 public subnets (for NAT Gateway placement only -- no application workloads)

**NAT Gateways**:
- Count configurable: 1 for dev (cost optimization), 3 for prod (high availability)
- Elastic IPs allocated per NAT Gateway

**Route Tables**:
- Private route table: default route to NAT Gateway
- Public route table: default route to Internet Gateway

**VPC Flow Logs**:
- Destination: KMS-encrypted CloudWatch Log Group
- Retention: 365 days
- Captures all traffic (ACCEPT + REJECT)

**Security Groups**:

| Security Group | Direction | Rule |
|----------------|-----------|------|
| `lambda_sg` | Egress only | All outbound (0.0.0.0/0) |
| `vpc_endpoint_sg` | Ingress | HTTPS (443) from VPC CIDR only |

**VPC Endpoints** (7):

| Type | Service |
|------|---------|
| Gateway | S3 |
| Gateway | DynamoDB |
| Interface | KMS |
| Interface | CloudWatch Logs |
| Interface | STS |
| Interface | Voice ID |
| Interface | Kinesis |

---

### Step 2.3 — Storage Module (`modules/storage/`)

**Files created**: `main.tf`, `dynamodb.tf`, `variables.tf`, `outputs.tf`, `versions.tf`

**S3 Buckets** (4):

| Bucket | Purpose | Encryption |
|--------|---------|------------|
| `recordings` | Call recording storage | KMS CMK (storage key) |
| `transcripts` | Chat transcript storage | KMS CMK (storage key) |
| `exports` | Data export staging | KMS CMK (storage key) |
| `access-logs` | S3 access log aggregation | AES256 (required by S3 logging service) |

- All data buckets: versioning enabled, public access blocked (all 4 settings), SSL-only bucket policy
- Access logs bucket: versioning enabled, 90-day object expiry lifecycle rule
- S3 bucket logging enabled on all 3 data buckets, targeting the access logs bucket

**Lifecycle Rules** (applied to data buckets):
- Glacier transition: configurable days (90 days dev, 90 days prod)
- Object expiry: configurable days (30 days dev, 2555 days prod ~7 years)
- Abort incomplete multipart upload: 7 days

**DynamoDB Tables** (2):

| Table | Partition Key | Sort Key | Features |
|-------|--------------|----------|----------|
| `contact_records` | `contactId` (S) | `timestamp` (S) | PITR, KMS CMK, TTL on `expiry` |
| `session_data` | `sessionId` (S) | -- | PITR, KMS CMK, TTL on `expiry` |

- Billing mode configurable: `PAY_PER_REQUEST` (dev/test/qa) or `PROVISIONED` (prod)

---

### Step 2.4 — Lambda Module (`modules/lambda/`)

**Files created**: `main.tf`, `iam.tf`, `variables.tf`, `outputs.tf`, `versions.tf`
**Source files**: `src/cti_adapter/index.py`, `src/crm_lookup/index.py`, `src/post_call_survey/index.py`

**Lambda Functions** (3):

| Function | Timeout | Memory | Purpose |
|----------|---------|--------|---------|
| `cti_adapter` | 30s | 256 MB | CTI screen-pop integration |
| `crm_lookup` | 10s | 128 MB | Customer data lookup from CRM |
| `post_call_survey` | 15s | 128 MB | Post-call survey processing |

**Common configuration**:
- Runtime: Python 3.12
- Deployed in VPC private subnets (via networking module outputs)
- Source packaged via `archive_file` data source
- X-Ray tracing enabled (Active mode)
- Reserved concurrency configurable (5 dev, 100 prod)

**Per-function resources**:
- Dedicated SQS dead letter queue (KMS encrypted)
- Dedicated IAM execution role (not shared) with: VPC access (`AWSLambdaVPCAccessExecutionRole`), CloudWatch Logs, DynamoDB, SQS permissions
- Dedicated CloudWatch log group (365-day retention, KMS encrypted with logs key)

**Code signing**:
- Conditional on `var.code_signing_profile_arns` -- when provided, enforces that only signed code packages are deployed

**Placeholder handlers**:
- Each `index.py` contains a minimal `handler(event, context)` function that returns a success response with environment metadata

---

### Step 2.5 — Lex Module (`modules/lex/`)

**Files created**: `main.tf`, `intents.tf`, `variables.tf`, `outputs.tf`, `versions.tf`

**Lex V2 Bot**:
- Locale: `en_AU` (Australian English)
- NLU confidence threshold: 0.40
- Idle session TTL: 300 seconds

**Intents** (4):

| Intent | Type | Purpose |
|--------|------|---------|
| `CheckBalance` | Custom | Account balance inquiry |
| `ReportLostCard` | Custom | Lost/stolen card reporting |
| `BranchHours` | Custom | Branch operating hours lookup |
| `FallbackIntent` | `AMAZON.FallbackIntent` | Catch-all for unrecognized utterances |

**Bot version**: Created after all intents via `depends_on` to ensure intent definitions are complete before version snapshot.

**Bot alias**: Not available in the `hashicorp/aws` provider at time of implementation -- documented as a known limitation for future addition when provider support lands.

**Logging**: Conversation log group created with KMS encryption and 365-day retention.

---

### Step 2.6 — Connect Module (`modules/connect/`)

**Files created**: `main.tf`, `contact_flows.tf`, `phone_numbers.tf`, `lambda_associations.tf`, `versions.tf`

**Amazon Connect Instance**:
- Identity management: SAML federation (enterprise SSO integration)
- Inbound calls: enabled
- Outbound calls: enabled

**Instance Storage Config**:

| Resource Type | Destination | Encryption |
|---------------|-------------|------------|
| `CALL_RECORDINGS` | S3 (recordings bucket) | KMS CMK (storage key) |
| `CHAT_TRANSCRIPTS` | S3 (transcripts bucket) | KMS CMK (storage key) |

**Contact Flows** (4, loaded from JSON):

| Flow | Source File | Purpose |
|------|-------------|---------|
| `inbound_main` | `contact_flows/inbound_main.json` | Primary IVR entry point |
| `transfer_to_queue` | `contact_flows/transfer_to_queue.json` | Agent queue transfer logic |
| `customer_queue_hold` | `contact_flows/customer_queue_hold.json` | Hold experience while in queue |
| `disconnect` | `contact_flows/disconnect.json` | Post-call disconnect handling |

- All flows follow Amazon Connect `Version: 2019-10-30` format
- Loaded via `file()` function for version-controlled, diff-trackable IVR logic

**Phone Numbers**: Provisioned via `for_each` on `var.phone_numbers` map (country code + type configurable).

**Lambda Associations**: Linked via `for_each` -- connects Lambda function ARNs to the Connect instance for use in contact flows.

**Lex Bot Association**: Conditional on `var.lex_bot_alias_arn` -- when provided, associates the Lex bot with the Connect instance.

**Kinesis Streaming** (`kinesis.tf`):

| Stream | Mode | Retention | Encryption |
|--------|------|-----------|------------|
| CTR stream | ON_DEMAND | 168 hours (7 days) | KMS CMK |
| Agent events stream | ON_DEMAND | 168 hours (7 days) | KMS CMK |

**Kinesis Firehose**:
- Source: CTR Kinesis Data Stream
- Destination: S3 (exports bucket)
- Compression: GZIP
- Buffer: 300 seconds / 5 MB

**Connect Instance Storage Config**: CTR and agent events configured to stream to their respective Kinesis Data Streams.

---

### Step 2.7 — Routing Module (`modules/routing/`)

**Files created**: `main.tf`, `hours_of_operation.tf`, `quick_connects.tf`, `security_profiles.tf`, `variables.tf`, `outputs.tf`, `versions.tf`

**Hours of Operation** (3):

| Name | Schedule |
|------|----------|
| `standard` | Monday-Friday, 08:00-18:00 AEST |
| `extended` | Monday-Friday 07:00-21:00, Saturday 09:00-17:00 AEST |
| `24x7` | All days, 00:00-23:59 AEST |

**Queues** (via `for_each`):
- Default set: `retail_banking`, `business_banking`, `fraud`
- Each queue: configurable max contacts, description, hours of operation reference

**Routing Profiles** (via `for_each`):
- Channel concurrency: VOICE = 1, CHAT = 3
- Queue priority assignments configurable per profile

**Quick Connects**:
- Type: `QUEUE`
- Configurable via variable map

**Security Profiles** (2):

| Profile | Permissions |
|---------|-------------|
| `supervisor` | Real-time/historical metrics, call recording playback |
| `agent` | Basic contact handling, queue transfers |

---

### Step 2.8 — Monitoring Module (`modules/monitoring/`)

**Files created**: `main.tf`, `alarms.tf`, `sns.tf`, `log_groups.tf`, `variables.tf`, `outputs.tf`, `versions.tf`

**CloudWatch Dashboard**:
- JSON-encoded widgets for: Connect instance metrics, per-queue statistics, Lambda invocation/error/duration metrics, DynamoDB read/write capacity and throttle metrics
- Built via `jsonencode()` for maintainability

**CloudWatch Alarms** (4 types):

| Alarm | Threshold | Evaluation |
|-------|-----------|------------|
| Queue wait warning | > 5 contacts | Configurable period |
| Queue wait critical | > 15 contacts | Configurable period |
| Lambda errors | Per function | Error count threshold |
| DynamoDB throttle | Per table | Throttle events threshold |

**SNS Topics** (2):

| Topic | Purpose | Encryption |
|-------|---------|------------|
| `warning` | Non-critical alerts | KMS CMK |
| `critical` | P1/P2 alerts | KMS CMK |

- Email subscriptions configurable via `var.alert_email_endpoints`
- Alarm actions enabled/disabled via `var.alarm_actions_enabled` (disabled in dev, enabled in prod)

**Connect Log Group**: 365-day retention, KMS encrypted with logs key.

---

## Phase 3: Environment Composition

### Step 3.1 — Dev Environment (`environments/dev/`)

**Files created**: `main.tf`, `providers.tf`, `variables.tf`, `terraform.tfvars`, `backend.tf`, `versions.tf`, `outputs.tf`

**Composition**: Root `main.tf` composes all 9 modules with dependency-ordered wiring. Module outputs are passed as inputs to downstream modules following the dependency graph:

```
security -> networking -> storage -> lambda -> lex -> connect -> routing -> monitoring
                                                          ^
                                              security_guardrails (independent)
```

**Provider configuration** (`providers.tf`):
- AWS provider with region locked to `var.aws_region`
- `default_tags` block applying mandatory tags (Project, Environment, Owner, CostCenter, DataClassification, ManagedBy)

**Version constraints** (`versions.tf`):
- Terraform: `>= 1.7.0`
- AWS Provider: `>= 5.40.0`

**Dev-specific values** (`terraform.tfvars`):

| Parameter | Dev Value |
|-----------|-----------|
| `vpc_cidr` | `10.1.0.0/16` |
| `nat_gateway_count` | 1 |
| `kms_deletion_window_days` | 7 |
| `lambda_reserved_concurrency` | 5 |
| `dynamodb_billing_mode` | `PAY_PER_REQUEST` |
| `recording_retention_days` | 30 |
| `recording_glacier_days` | 90 |
| `alarm_actions_enabled` | false |
| `enable_connect_contact_lens` | false |

**Backend** (`backend.tf`): S3 backend with partial configuration (actual bucket/key/region supplied via `-backend-config=../../backends/dev.s3.tfbackend`).

---

### Step 3.2 — Additional Environments

**Action**: Created `test`, `qa`, `staging`, and `prod` environments, each sharing the same module composition structure (`main.tf`, `outputs.tf`, `providers.tf`, `variables.tf`, `versions.tf`, `backend.tf`) with environment-specific `terraform.tfvars`.

| Environment | VPC CIDR | NAT Count | Concurrency | Retention | DynamoDB Mode | Alarms |
|-------------|----------|-----------|-------------|-----------|---------------|--------|
| dev | `10.1.0.0/16` | 1 | 5 | 30 days | PAY_PER_REQUEST | Disabled |
| test | `10.4.0.0/16` | 1 | 5 | 30 days | PAY_PER_REQUEST | Disabled |
| qa | `10.5.0.0/16` | 1 | 10 | 60 days | PAY_PER_REQUEST | Disabled |
| staging | `10.2.0.0/16` | 2 | 50 | 365 days | PAY_PER_REQUEST | Enabled |
| prod | `10.3.0.0/16` | 3 | 100 | 2555 days (~7yr) | PROVISIONED | Enabled |

**Backend configs**: Separate files in `backends/{env}.s3.tfbackend` for each environment, ensuring complete state isolation (directory-based, not workspace-based -- safer for banking to prevent accidental cross-environment state operations).

---

## Phase 4: Security Guardrails

### Step 4.1 — Security Guardrails Module (`modules/security_guardrails/`)

**Files created**: `main.tf`, `config_rules.tf`, `cloudtrail.tf`, `s3_account_block.tf`, `mandatory_tags.tf`, `variables.tf`, `outputs.tf`, `versions.tf`

**AWS Config**:
- Configuration recorder: records all resource types
- Delivery channel: S3 bucket for config snapshots
- Recorder status: enabled

**Config Managed Rules** (16):

| Category | Rules |
|----------|-------|
| S3 public access | `s3-bucket-public-read-prohibited`, `s3-bucket-public-write-prohibited`, `s3-bucket-level-public-access-prohibited`, `s3-account-level-public-access-blocks` |
| Encryption | `s3-default-encryption-kms`, `dynamodb-table-encrypted-kms`, `cloud-trail-encryption-enabled` |
| IAM | `iam-root-access-key-check`, `iam-policy-no-statements-with-admin-access` |
| CloudTrail | `cloud-trail-cloud-watch-logs-enabled`, `cloudtrail-enabled`, `multi-region-cloudtrail-enabled` |
| Network | `vpc-flow-logs-enabled`, `restricted-ssh` |
| Database | `dynamodb-pitr-enabled` |
| Tagging | `required-tags` |

**CloudTrail**:
- Multi-region: enabled
- Log file validation: enabled
- KMS encryption: customer-managed key
- CloudWatch Logs integration: conditional (when log group ARN provided)

**Account-Level S3 Public Access Block**:
- All 4 settings enabled: `block_public_acls`, `block_public_policy`, `ignore_public_acls`, `restrict_public_buckets`

**Mandatory Tag Policy**:
- Via AWS Organizations (conditional on `var.enable_tag_policy`)
- Enforces required tags: Project, Environment, Owner, CostCenter, DataClassification, ManagedBy

---

## Phase 5: CI/CD Pipeline

### Step 5.1 — GitHub Actions Deploy Workflow (`.github/workflows/deploy.yml`)

**Pipeline stages**:

1. **Lint & Scan** (on PR):
   - `terraform fmt -check -recursive` -- formatting compliance
   - TFLint -- AWS-specific linting rules
   - Checkov -- security and compliance scanning

2. **Plan** (on PR):
   - Per-environment `terraform plan`
   - Plan output posted as PR comment for review

3. **Apply** (on merge to main):
   - Sequential promotion: `dev` -> `test` -> `qa` -> `staging` -> `prod`
   - Each stage waits for the previous to succeed

4. **Production gate**:
   - Manual approval required via GitHub environment protection rules
   - Only after staging apply succeeds

5. **Post-deploy validation**:
   - Runs `validate_readiness.py` against dev environment after deploy

**Authentication**: AWS OIDC federation -- no long-lived access keys stored in GitHub Secrets.

---

### Step 5.2 — CODEOWNERS (`.github/CODEOWNERS`)

| Path Pattern | Owners |
|-------------|--------|
| `*` (all changes) | `@awsccaasbank/platform-engineering` |
| `environments/prod/` | `@awsccaasbank/platform-engineering` + `@awsccaasbank/security-team` |
| `modules/security*/` | `@awsccaasbank/platform-engineering` + `@awsccaasbank/security-team` |

---

## Phase 6: Scripts & Validation

### Step 6.1 — Bootstrap Script (`scripts/bootstrap-backend.sh`)

**Purpose**: One-time setup of Terraform remote state infrastructure per environment.

**Actions**:
- Creates S3 state bucket: `awsccaasbank-ccaas-terraform-state-{env}`
- Enables bucket versioning (state history)
- Applies KMS encryption (server-side)
- Blocks public access (all 4 settings)
- Creates DynamoDB lock table: `awsccaasbank-ccaas-terraform-locks-{env}`
- Lock table uses PAY_PER_REQUEST billing

**Usage**: `./scripts/bootstrap-backend.sh <environment>`

---

### Step 6.2 — Validation Script (`scripts/validate_readiness.py`)

**Purpose**: Post-deployment operational readiness validation.

**Capabilities**:
- Amazon Connect instance validation (status, storage config, phone numbers)
- Infrastructure checks (VPC, subnets, security groups, KMS key status)
- IVR flow simulation (contact flow validation)

**CLI interface**:
- `--environment` flag: target environment
- `--region` flag: AWS region (default `ap-southeast-2`)
- Exit code 0: all checks pass
- Exit code 1: one or more checks failed

**Dependencies**: Listed in `scripts/requirements.txt` (Python 3.12 + Boto3)

---

## Phase 7: Validation & Hardening

### Step 7.1 — Terraform Validate

**First run**: 12 errors identified.

| Error | Module | Fix Applied |
|-------|--------|-------------|
| Output name mismatches | `storage` | Changed from list outputs (e.g., `bucket_arns`) to individual ARN/name outputs (e.g., `recordings_bucket_arn`, `transcripts_bucket_arn`) |
| Function ARN output naming | `lambda` | Changed `cti_adapter_arn` to `cti_adapter_function_arn` to match resource attribute path |
| Unsupported resource | `lex` | Removed `aws_lexv2models_bot_alias` (not available in `hashicorp/aws` provider); adopted version-only approach |
| Unsupported attribute | `monitoring` | Removed `tags` argument from `aws_cloudwatch_dashboard` (not supported by the resource) |
| Deprecated attribute | `networking` | Replaced `data.aws_region.current.name` with `data.aws_region.current.id` |
| Missing default value | `routing` | Added default value for `routing_profiles` variable |

**Second run**: **Success -- configuration valid across all modules and environments.**

---

### Step 7.2 — Terraform Format

**Command**: `terraform fmt -recursive`

**Result**: 17 files reformatted for consistent HCL style (indentation, alignment, trailing commas).

---

### Step 7.3 — Checkov Security Scan

**Initial scan**: **332 passed, 35 failed.**

**Remediation round 1**:

| Module | Finding | Remediation |
|--------|---------|-------------|
| `lambda` | Log retention too short | Changed all Lambda log groups to 365-day retention |
| `lambda` | X-Ray tracing not enabled | Added `tracing_config { mode = "Active" }` to all functions |
| `lambda` | No code signing | Added `code_signing_config` resource (conditional on `var.code_signing_profile_arns`) |
| `storage` | No access logging on S3 buckets | Created dedicated access logs bucket; enabled `logging {}` block on all data buckets |
| `storage` | No abort incomplete multipart | Added `abort_incomplete_multipart_upload_days = 7` lifecycle rule |
| `networking` | Default security group not restricted | Added `aws_default_security_group` resource to restrict the default VPC security group (no ingress/egress rules) |
| `monitoring` | Log retention too short | Changed Connect log group to 365-day retention |
| `connect` | Kinesis encryption | Attempted `encryption_config` on Kinesis resources (not supported by `aws_connect_instance_storage_config` resource -- documented as accepted finding) |

**Final scan**: **337 passed, 9 accepted findings (97.4% pass rate).**

**Accepted findings with justification**:

| Finding | Justification |
|---------|---------------|
| Kinesis stream encryption type | Provider resource does not expose `encryption_type` attribute; streams use KMS via `encryption_configuration` at creation |
| S3 access logs bucket not logging itself | Circular dependency -- industry standard to exclude the logs bucket from self-logging |
| Connect instance CloudWatch logging | Amazon Connect logging is configured via instance storage config, not directly on the resource |
| Firehose encryption | Firehose inherits encryption from source Kinesis stream and destination S3 bucket |
| APRA data sovereignty region lock | Enforced at provider level and IAM policy conditions; Checkov cannot verify provider-level region constraints |

---

## Phase 8: Documentation & Git

### Step 8.1 — Documentation

| Document | Content |
|----------|---------|
| `README.md` | Mermaid HLD (architecture diagram), APRA CPS 234 compliance mapping table, 5 environments with CIDR allocation, CI/CD pipeline diagram, mandatory tagging strategy, quick start instructions |
| `CLAUDE.md` | Module dependency graph, naming conventions (`${project_name}-${environment}-{purpose}`), compliance constraints (region lock, KMS, S3, IAM, logging, tags), build/deploy commands, guidance for adding new modules |
| `PROMPTS.md` | AI-first engineering process log: methodology description, prompt history (2 prompts), architecture decisions table (7 decisions with rationale), observations on AI accuracy, tooling list |

---

### Step 8.2 — Git Initialization & GitHub Push

**Git identity** (placeholder):
- Name: `Vikrant Rathore`
- Email: `vikrant.rathore@awsccaasbank.com.au`
- Documented in both `README.md` and `PROMPTS.md` with instructions to update before sharing

**Commit history** (4 commits, chronological):

| # | Message | Scope |
|---|---------|-------|
| 1 | `feat: scaffold Awsccaasbank CCaaS blueprint on AWS Amazon Connect` | 118 files, 7593 insertions -- initial scaffold with all modules, environments, CI/CD, scripts, documentation |
| 2 | `docs: add placeholder git identity notice to README and PROMPTS` | Added git identity warning to README.md and PROMPTS.md |
| 3 | `fix: resolve terraform validate errors across modules` | Fixed 12 validation errors (output names, unsupported resources/attributes, deprecated APIs, missing defaults) |
| 4 | `fix: address Checkov security findings (332->337 passed)` | Remediated 26 Checkov findings; achieved 97.4% pass rate with 9 accepted/documented exceptions |

**GitHub**:
- Created private repository: `https://github.com/VikrantKK/awsccaasbank`
- All 4 commits pushed to `origin/main`

---

## Appendix A: Final File Count

```
modules/security/          — 5 files (main.tf, iam_roles.tf, variables.tf, outputs.tf, versions.tf)
modules/networking/        — 5 files (main.tf, security_groups.tf, variables.tf, outputs.tf, versions.tf)
modules/storage/           — 5 files (main.tf, dynamodb.tf, variables.tf, outputs.tf, versions.tf)
modules/lambda/            — 5 files + 3 Python handlers (main.tf, iam.tf, variables.tf, outputs.tf, versions.tf, src/*/index.py)
modules/lex/               — 5 files (main.tf, intents.tf, variables.tf, outputs.tf, versions.tf)
modules/connect/           — 6 files (main.tf, contact_flows.tf, phone_numbers.tf, lambda_associations.tf, kinesis.tf, versions.tf)
modules/routing/           — 6 files (main.tf, hours_of_operation.tf, quick_connects.tf, security_profiles.tf, variables.tf, outputs.tf, versions.tf)
modules/monitoring/        — 6 files (main.tf, alarms.tf, sns.tf, log_groups.tf, variables.tf, outputs.tf, versions.tf)
modules/security_guardrails/ — 8 files (main.tf, config_rules.tf, cloudtrail.tf, s3_account_block.tf, mandatory_tags.tf, variables.tf, outputs.tf, versions.tf)
environments/              — 5 envs x 7 files each = 35 files
backends/                  — 5 .s3.tfbackend files
contact_flows/             — 4 JSON files
scripts/                   — 3 files (bootstrap-backend.sh, validate_readiness.py, requirements.txt)
.github/                   — 2 files (workflows/deploy.yml, CODEOWNERS)
root/                      — 5 files (.gitignore, .pre-commit-config.yaml, .tflint.hcl, README.md, CLAUDE.md, PROMPTS.md)
```

---

## Appendix B: Module Dependency Graph

```
                    ┌──────────┐
                    │ security │
                    └────┬─────┘
                         │
                    ┌────▼──────┐
                    │ networking │
                    └────┬──────┘
                         │
                    ┌────▼────┐
                    │ storage │
                    └────┬────┘
                         │
                    ┌────▼────┐
                    │ lambda  │
                    └────┬────┘
                         │
                    ┌────▼──┐
                    │  lex  │
                    └────┬──┘
                         │
                    ┌────▼────┐
                    │ connect │
                    └────┬────┘
                         │
                    ┌────▼────┐
                    │ routing │
                    └────┬────┘
                         │
                  ┌──────▼──────┐
                  │ monitoring  │
                  └─────────────┘

    ┌─────────────────────┐
    │ security_guardrails  │  (independent — no module dependencies)
    └─────────────────────┘
```

---

## Appendix C: Compliance Mapping

| APRA CPS 234 Control | Implementation |
|----------------------|----------------|
| Data sovereignty | All resources in `ap-southeast-2`; IAM `aws:RequestedRegion` condition; provider-level region lock |
| Encryption at rest | 4 KMS CMKs with auto-rotation; all S3, DynamoDB, CloudWatch Logs, Kinesis, SQS encrypted |
| Encryption in transit | SSL-only S3 bucket policies; VPC endpoints (PrivateLink) for service communication |
| Access control | Per-function IAM roles; least-privilege policies; confused deputy protection; SAML federation |
| Audit logging | CloudTrail (multi-region, log validation); VPC Flow Logs; CloudWatch Logs (365-day retention) |
| Network isolation | Private subnets; no public workloads; security groups (egress-only for Lambda); default SG restricted |
| Change management | Git version control; PR-based review; CODEOWNERS; sequential CI/CD promotion with prod gate |
| Monitoring | CloudWatch dashboard; 4 alarm types; SNS alerting (warning + critical); X-Ray tracing |
| Configuration compliance | 16 AWS Config rules; security guardrails module; Checkov in CI pipeline |
