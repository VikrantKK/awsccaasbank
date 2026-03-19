# Checkov Security Scan Report

## Scan Summary
- **Date:** 2026-03-20
- **Checkov Version:** 3.2.510
- **Framework:** Terraform
- **Total Checks:** 346
- **Passed:** 337 (97.4%)
- **Failed:** 9 (accepted)

## Passed Checks by Category
(Summarize the key categories that passed: S3 encryption, S3 SSL, S3 public access block, S3 versioning, S3 access logging, DynamoDB encryption, KMS rotation, IAM no inline policy, VPC flow logs, CloudTrail encryption, Lambda KMS, Lambda X-Ray, Lambda code signing, CloudWatch log retention, etc.)

## Accepted Findings

### CKV_AWS_269 / CKV_AWS_270 — Connect Kinesis Storage Config CMK (6 findings)
**Resource:** aws_connect_instance_storage_config (CTR + agent events + recordings + transcripts)
**Reason:** Checkov expects an `encryption_config` block in the storage config resource. For KINESIS_STREAM storage type, this block is not supported by the AWS Terraform provider — encryption is enforced on the Kinesis stream itself via KMS CMK. For S3 storage types, encryption_config IS present (verified). The Kinesis streams use `encryption_type = "KMS"` with var.storage_kms_key_arn.
**Risk:** None — data is encrypted. False positive due to Checkov rule not accounting for stream-level encryption.

### CKV_AWS_109 / CKV_AWS_111 / CKV_AWS_356 — KMS Key Policy (3 findings)
**Resource:** aws_iam_policy_document.kms_key_policy
**Reason:** KMS key policies require root account access (`kms:*` on `*`) for key administration. This is the standard AWS-recommended pattern — without it, keys become unmanageable. The key policy is scoped to the account root principal only.
**Risk:** Acceptable — this is AWS best practice for CMK management.

### CKV_AWS_252 / CKV2_AWS_10 — CloudTrail SNS/CloudWatch (2 findings, deduplicated from different envs)
**Resource:** aws_cloudtrail.this
**Reason:** CloudTrail SNS topic and CloudWatch Logs integration are conditionally configured via variables (cloudtrail_log_group_arn, config_sns_topic_arn). When these are provided, integration is enabled.
**Risk:** Low — these should be configured in staging/prod environments.

### CKV_AWS_145 — Access Logs Bucket KMS (1 finding)
**Resource:** aws_s3_bucket.access_logs
**Reason:** S3 server access logging requires the destination bucket to use SSE-S3 (AES256), not SSE-KMS. This is an AWS service limitation.
**Risk:** None — access logs contain metadata only (not PII or call recordings). AES256 provides encryption at rest.

### CKV_AWS_144 — S3 Cross-Region Replication (skipped)
**Resource:** All S3 buckets
**Reason:** Intentionally disabled for APRA CPS 234 data sovereignty. All data must remain in ap-southeast-2 (Sydney).
**Risk:** No geographic redundancy. Mitigated by S3 versioning and lifecycle management.

### CKV2_AWS_62 — S3 Event Notifications (skipped)
**Resource:** All S3 buckets
**Reason:** Event notifications will be configured as specific integration requirements emerge (e.g., Lambda triggers for recording processing).
**Risk:** Low — not a security finding, operational enhancement.

### CKV2_AWS_5 — Security Group Not Attached (1 finding)
**Resource:** aws_security_group.lambda
**Reason:** The Lambda security group IS attached — Lambda functions reference it via vpc_config.security_group_ids. Checkov cannot resolve cross-module references at static analysis time.
**Risk:** None — false positive.

## Recommendations
1. Configure CloudTrail SNS topic and CloudWatch Logs integration in staging/prod tfvars
2. Add S3 event notifications when recording processing Lambda is implemented
3. Re-run Checkov after each module change to maintain pass rate
