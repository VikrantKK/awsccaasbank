# Architecture Decision Records — Awsccaasbank CCaaS Blueprint

This document captures the key architectural decisions made for the Awsccaasbank Contact Centre as a Service (CCaaS) Terraform Blueprint. Each decision is recorded using the ADR (Architecture Decision Record) format to provide traceability, rationale, and consequence analysis for reviewers, auditors, and future maintainers.

---

## ADR-001: Directory-Based Environment Isolation Over Workspaces

**Status:** Accepted
**Date:** 2025-01-15

**Context:** Terraform workspaces vs directory-based isolation for multi-environment deployments. The blueprint must support dev, test, qa, staging, and prod environments with strong isolation guarantees suitable for a regulated financial institution.

**Decision:** Each environment (dev, test, qa, staging, prod) has its own directory under `environments/` with separate state files.

**Rationale:** For a banking platform under APRA regulation, workspace-based isolation is too risky — a `terraform destroy` in the wrong workspace could affect production. Directory isolation provides physical separation of state and prevents accidental cross-environment operations. Each environment directory contains its own `main.tf`, `outputs.tf`, backend configuration, and `terraform.tfvars`, ensuring that a Terraform operation in one directory cannot impact another environment's resources.

**Consequences:**
- More file duplication (`main.tf`, `outputs.tf` shared across envs), but significantly safer for regulated workloads.
- Shared logic is centralised in reusable modules under `modules/`, minimising drift between environments.
- Each environment maintains an independent state file in a dedicated S3 backend path.

---

## ADR-002: Four Separate KMS Keys Instead of One Shared Key

**Status:** Accepted
**Date:** 2025-01-15

**Context:** Whether to use a single KMS CMK or dedicated keys per data classification. Amazon Connect deployments involve multiple data types with different sensitivity levels: instance configuration, call recordings, metadata in DynamoDB, and operational logs.

**Decision:** 4 separate KMS CMKs: `connect` (instance encryption), `storage` (S3 buckets), `dynamodb` (tables), `logs` (CloudWatch).

**Rationale:** Separate keys allow independent rotation schedules, distinct access policies per data type, granular audit trails, and align with APRA CPS 234 information classification requirements. For example, the key encrypting call recordings (storage) can have a stricter access policy than the key used for operational logs.

**Consequences:**
- More key management overhead, but better security posture and compliance alignment.
- Each key has its own alias, rotation policy, and IAM key policy scoped to the services that need it.
- Key deletion protection and automatic annual rotation are enabled on all keys.

---

## ADR-003: Per-Function Lambda IAM Roles

**Status:** Accepted
**Date:** 2025-01-15

**Context:** Shared vs dedicated IAM execution roles for Lambda functions. The blueprint deploys multiple Lambda functions for CTI integration, CRM lookup, real-time transcription processing, and other contact centre automation tasks.

**Decision:** Each Lambda function gets its own IAM role with scoped permissions.

**Rationale:** True least-privilege — the CTI adapter doesn't need the same permissions as the CRM lookup. A compromise in one function doesn't grant lateral access to resources used by others. This aligns with APRA CPS 234 requirements for access control and minimisation of privilege.

**Consequences:**
- More IAM resources to manage, but significantly reduced blast radius.
- Each role's policy can be reviewed independently during security audits.
- Role naming convention (`{project}-{env}-{function_name}-role`) provides clear auditability.

---

## ADR-004: SAML Federation for Connect Identity

**Status:** Accepted
**Date:** 2025-01-15

**Context:** Amazon Connect supports three identity management modes: `CONNECT_MANAGED`, `SAML`, and `EXISTING_DIRECTORY`. Awsccaasbank has established enterprise identity infrastructure with MFA enforcement.

**Decision:** Use SAML federation.

**Rationale:** Awsccaasbank has existing corporate identity infrastructure. SAML integrates with the bank's IdP (e.g., Azure AD/Okta), enforces MFA, and avoids managing agent credentials within Connect. This provides single sign-on for agents, centralised provisioning/deprovisioning, and consistent authentication policies across the enterprise.

**Consequences:**
- Requires IdP configuration outside Terraform, but aligns with enterprise SSO strategy.
- Agent lifecycle management is handled through the corporate IdP rather than Connect-native user management.
- IdP metadata and relay state configuration must be coordinated with the identity team.

---

## ADR-005: Kinesis ON_DEMAND Mode for Non-Production

**Status:** Accepted
**Date:** 2025-01-15

**Context:** Kinesis streams can use `PROVISIONED` (fixed shard count) or `ON_DEMAND` (auto-scaling) capacity. The blueprint provisions Kinesis streams for Contact Trace Records (CTR) and agent event streaming.

**Decision:** `ON_DEMAND` for dev/test/qa, configurable for staging/prod.

**Rationale:** Non-prod environments have unpredictable load patterns. `ON_DEMAND` eliminates shard management overhead. Prod can use `PROVISIONED` for cost predictability and capacity planning based on known call volumes.

**Consequences:**
- `ON_DEMAND` may have slightly higher per-record cost but eliminates over/under-provisioning risk.
- The `stream_mode` variable in `terraform.tfvars` allows each environment to choose its capacity mode.
- Prod environments benefit from explicit shard count planning aligned with expected peak call volumes.

---

## ADR-006: VPC PrivateLink for Voice ID and Kinesis

**Status:** Accepted
**Date:** 2025-01-15

**Context:** Whether to route AWS API calls via public internet or VPC endpoints. The blueprint handles sensitive data including voice biometric enrolments and real-time contact event streams.

**Decision:** Interface VPC endpoints for KMS, CloudWatch Logs, STS, Voice ID, and Kinesis Streams. Gateway endpoints for S3 and DynamoDB.

**Rationale:** Voice biometric data (Voice ID) and real-time event streams must not traverse the public internet per APRA data-in-transit controls. VPC endpoints also reduce NAT Gateway data transfer costs. Gateway endpoints for S3 and DynamoDB are free and provide the same traffic isolation benefits.

**Consequences:**
- Additional cost for interface endpoints (~$0.01/GB + $0.01/hr per AZ), justified by compliance and security requirements.
- All endpoints are configured with private DNS enabled, so no application code changes are needed.
- Security groups on interface endpoints restrict access to the VPC CIDR only.

---

## ADR-007: Contact Flows as Version-Controlled JSON

**Status:** Accepted
**Date:** 2025-01-15

**Context:** Contact flows can be built in the Amazon Connect console GUI or managed as code. Contact flows define the IVR logic, routing rules, and customer experience for all inbound interactions.

**Decision:** Store contact flow definitions as JSON files in `contact_flows/`, loaded via Terraform `file()` function.

**Rationale:** Enables code review, diff tracking, rollback, and audit trail for IVR logic changes. Aligns with Infrastructure as Code principles and provides a complete audit history of every change to customer-facing call routing.

**Consequences:**
- JSON is verbose and harder to edit manually. Recommend using Connect's visual designer to build flows, export as JSON, then version-control the export.
- All flow changes go through the same PR review and CI/CD pipeline as infrastructure changes.
- Flow definitions can reference dynamic resources (Lambda ARNs, queue ARNs) via Terraform interpolation.

---

## ADR-008: Sequential CI/CD Promotion With Manual Prod Gate

**Status:** Accepted
**Date:** 2025-01-15

**Context:** How to safely promote infrastructure changes to production. The pipeline must balance deployment velocity with the risk controls expected of a major Australian bank.

**Decision:** Sequential promotion: dev → test → qa → staging → [manual approval] → prod. Single `deploy.yml` workflow.

**Rationale:** Progressive confidence building — issues found in lower environments don't reach production. Manual prod gate ensures human oversight for bank-critical infrastructure. OIDC federation eliminates long-lived AWS credentials in CI/CD.

**Consequences:**
- Slower time-to-prod, but appropriate for regulated financial infrastructure.
- Each environment stage runs `terraform plan` and `terraform apply` independently.
- The manual approval step creates an auditable record of who authorised the production deployment.

---

## ADR-009: Checkov Over tfsec as Primary Security Scanner

**Status:** Accepted
**Date:** 2025-01-15

**Context:** Multiple Terraform security scanning tools exist (Checkov, tfsec, Trivy, Terrascan). The blueprint needs automated policy enforcement in CI/CD to catch security misconfigurations before deployment.

**Decision:** Checkov as primary scanner in CI/CD, with tfsec in pre-commit hooks.

**Rationale:** Checkov has broader rule coverage (1000+ checks), supports custom policies, outputs SARIF for GitHub Security tab integration, and has active maintenance. Using both provides defense-in-depth — tfsec catches issues at commit time, Checkov provides comprehensive scanning in the pipeline.

**Consequences:**
- Longer CI scan times, but comprehensive security coverage.
- Known acceptable exceptions (e.g., ADR-011, ADR-012) are documented with skip comments referencing the relevant ADR.
- SARIF output integrates with GitHub Advanced Security for centralised findings management.

---

## ADR-010: AWS Config Rules for APRA Compliance Monitoring

**Status:** Accepted
**Date:** 2025-01-15

**Context:** How to continuously monitor compliance with APRA CPS 234 (Information Security) and CPG 234 (Information Security Management). Point-in-time audits are insufficient for a production contact centre platform.

**Decision:** Dedicated `security_guardrails` module with 16 AWS Config managed rules, CloudTrail, and account-level S3 public access block.

**Rationale:** AWS Config provides continuous compliance monitoring and drift detection. Rules cover encryption, public access, IAM hygiene, audit logging, and mandatory tagging — directly mapping to APRA CPS 234 / CPG 234 controls. CloudTrail provides the audit log required for forensic investigation of security events.

**Consequences:**
- AWS Config has per-rule pricing, but required for regulatory compliance posture management.
- Non-compliant resources trigger automated notifications for remediation.
- Config rule evaluation results provide evidence for APRA regulatory examinations.

---

## ADR-011: S3 Access Logs Bucket Uses AES256 Not KMS

**Status:** Accepted
**Date:** 2025-01-15

**Context:** All data buckets use KMS CMK encryption. The access logs destination bucket triggers Checkov finding CKV_AWS_145 (S3 bucket not encrypted with KMS).

**Decision:** Access logs bucket uses AES256 (SSE-S3) encryption.

**Rationale:** AWS S3 server access logging requires the destination bucket to use SSE-S3 (AES256), not SSE-KMS. This is an AWS limitation, not a design choice. Attempting to use KMS encryption on the log delivery destination bucket causes log delivery to fail silently.

**Consequences:**
- Accepted Checkov finding CKV_AWS_145. The skip is documented with an inline comment referencing this ADR.
- The access logs contain metadata only (request timestamps, source IPs, object keys), not PII or call recordings.
- The bucket still has versioning, public access block, and lifecycle policies applied.

---

## ADR-012: No S3 Cross-Region Replication

**Status:** Accepted
**Date:** 2025-01-15

**Context:** Checkov flags missing cross-region replication (CKV_AWS_144) on all S3 buckets. Cross-region replication would copy data to a second AWS region for geographic redundancy.

**Decision:** Intentionally disabled. All data stays in `ap-southeast-2` (Sydney).

**Rationale:** APRA CPS 234 requires data sovereignty — customer data, call recordings, and transcripts must remain in the Sydney region. Cross-region replication would violate this requirement by copying regulated data to another geographic location without explicit regulatory approval.

**Consequences:**
- No geographic redundancy. DR strategy relies on S3 versioning + Object Lock, not cross-region copies.
- Accepted Checkov finding CKV_AWS_144. The skip is documented with an inline comment referencing this ADR.
- If multi-region DR is required in the future, it must go through APRA regulatory approval and data sovereignty review.
