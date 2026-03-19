locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# =============================================================================
# Phase 1 — Security (KMS keys, IAM roles)
# =============================================================================

module "security" {
  source = "../../modules/security"

  environment              = var.environment
  project_name             = var.project_name
  aws_region               = var.aws_region
  kms_deletion_window_days = var.kms_deletion_window_days
  dynamodb_table_arns = [
    module.storage.contact_records_table_arn,
    module.storage.session_data_table_arn,
  ]
  s3_bucket_arns = [
    module.storage.recordings_bucket_arn,
    module.storage.transcripts_bucket_arn,
    module.storage.exports_bucket_arn,
  ]
  tags = local.common_tags
}

# =============================================================================
# Phase 2 — Networking (VPC, subnets, endpoints)
# =============================================================================

module "networking" {
  source = "../../modules/networking"

  environment       = var.environment
  project_name      = var.project_name
  vpc_cidr          = var.vpc_cidr
  nat_gateway_count = var.nat_gateway_count
  logs_kms_key_arn  = module.security.logs_kms_key_arn
  tags              = local.common_tags
}

# =============================================================================
# Phase 3 — Storage (S3 buckets, DynamoDB tables)
# =============================================================================

module "storage" {
  source = "../../modules/storage"

  environment              = var.environment
  project_name             = var.project_name
  storage_kms_key_arn      = module.security.storage_kms_key_arn
  dynamodb_kms_key_arn     = module.security.dynamodb_kms_key_arn
  dynamodb_billing_mode    = var.dynamodb_billing_mode
  recording_glacier_days   = var.recording_glacier_days
  recording_retention_days = var.recording_retention_days
  tags                     = local.common_tags
}

# =============================================================================
# Phase 4 — Lambda (integration functions)
# =============================================================================

module "lambda" {
  source = "../../modules/lambda"

  environment                 = var.environment
  project_name                = var.project_name
  subnet_ids                  = module.networking.private_subnet_ids
  lambda_security_group_id    = module.networking.lambda_security_group_id
  lambda_kms_key_arn          = module.security.connect_kms_key_arn
  logs_kms_key_arn            = module.security.logs_kms_key_arn
  dynamodb_contact_table_arn  = module.storage.contact_records_table_arn
  dynamodb_session_table_arn  = module.storage.session_data_table_arn
  dynamodb_contact_table_name = module.storage.contact_records_table_name
  dynamodb_session_table_name = module.storage.session_data_table_name
  connect_instance_id         = module.connect.instance_id
  reserved_concurrency        = var.lambda_reserved_concurrency
  tags                        = local.common_tags
}

# =============================================================================
# Phase 5 — Lex (IVR self-service bots)
# =============================================================================

module "lex" {
  source = "../../modules/lex"

  environment          = var.environment
  project_name         = var.project_name
  lex_service_role_arn = module.security.lex_service_role_arn
  logs_kms_key_arn     = module.security.logs_kms_key_arn
  tags                 = local.common_tags
}

# =============================================================================
# Phase 6 — Connect (core instance, contact flows)
# =============================================================================

module "connect" {
  source = "../../modules/connect"

  environment             = var.environment
  project_name            = var.project_name
  recordings_bucket_name  = module.storage.recordings_bucket_id
  transcripts_bucket_name = module.storage.transcripts_bucket_id
  storage_kms_key_arn     = module.security.storage_kms_key_arn
  phone_numbers           = var.phone_numbers
  lambda_function_arns = [
    module.lambda.cti_adapter_function_arn,
    module.lambda.crm_lookup_function_arn,
    module.lambda.post_call_survey_function_arn,
  ]
  lex_bot_alias_arn = module.lex.bot_alias_arn
  lex_bot_id        = module.lex.bot_id
  tags              = local.common_tags
}

# =============================================================================
# Phase 7 — Routing (queues, profiles, hours of operation)
# =============================================================================

module "routing" {
  source = "../../modules/routing"

  environment              = var.environment
  project_name             = var.project_name
  connect_instance_id      = module.connect.instance_id
  transfer_contact_flow_id = module.connect.contact_flow_ids["transfer_to_queue"]
  tags                     = local.common_tags
}

# =============================================================================
# Phase 8 — Monitoring (dashboards, alarms)
# =============================================================================

module "monitoring" {
  source = "../../modules/monitoring"

  environment         = var.environment
  project_name        = var.project_name
  logs_kms_key_arn    = module.security.logs_kms_key_arn
  connect_instance_id = module.connect.instance_id
  lambda_function_names = [
    module.lambda.cti_adapter_function_name,
    module.lambda.crm_lookup_function_name,
    module.lambda.post_call_survey_function_name,
  ]
  dynamodb_table_names = [
    module.storage.contact_records_table_name,
    module.storage.session_data_table_name,
  ]
  alarm_actions_enabled = var.alarm_actions_enabled
  alert_email_endpoints = var.alert_email_endpoints
  tags                  = local.common_tags
}
