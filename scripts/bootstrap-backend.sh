#!/usr/bin/env bash
# Bootstrap S3 backend and DynamoDB lock table for Terraform state
set -euo pipefail

ENV="${1:?Usage: $0 <environment>}"
PROJECT="westpac-ccaas"
REGION="ap-southeast-2"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

BUCKET_NAME="${PROJECT}-terraform-state-${ENV}"
TABLE_NAME="${PROJECT}-terraform-locks-${ENV}"

echo "Bootstrapping Terraform backend for ${ENV}..."

# Create S3 bucket
aws s3api create-bucket \
  --bucket "${BUCKET_NAME}" \
  --region "${REGION}" \
  --create-bucket-configuration LocationConstraint="${REGION}"

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "aws:kms"}, "BucketKeyEnabled": true}]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Create DynamoDB lock table
aws dynamodb create-table \
  --table-name "${TABLE_NAME}" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "${REGION}" \
  --tags Key=Project,Value="${PROJECT}" Key=Environment,Value="${ENV}" Key=ManagedBy,Value=bootstrap

echo "Backend bootstrapped: bucket=${BUCKET_NAME} table=${TABLE_NAME}"
