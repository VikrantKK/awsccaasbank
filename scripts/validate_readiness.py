#!/usr/bin/env python3
"""
Westpac CCaaS Amazon Connect Blueprint - Readiness Validation Script

Validates that all AWS infrastructure components for the Westpac CCaaS
Amazon Connect deployment are correctly provisioned and configured.

Dependencies: boto3 (see requirements.txt)
"""

import argparse
import logging
import sys
import time
import json
from dataclasses import dataclass, field
from typing import Optional

import boto3
from botocore.exceptions import ClientError

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)
logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Data structures
# ---------------------------------------------------------------------------

@dataclass
class CheckResult:
    name: str
    passed: bool
    detail: str = ""


@dataclass
class ReadinessReport:
    results: list = field(default_factory=list)

    def add(self, result: CheckResult):
        self.results.append(result)

    @property
    def all_passed(self) -> bool:
        return all(r.passed for r in self.results)

    def print_report(self):
        width = 80
        print("\n" + "=" * width)
        print("  WESTPAC CCaaS AMAZON CONNECT - READINESS REPORT")
        print("=" * width)
        passed_count = sum(1 for r in self.results if r.passed)
        total = len(self.results)
        for r in self.results:
            status = "PASS" if r.passed else "FAIL"
            marker = "[+]" if r.passed else "[-]"
            line = f"  {marker} {status}  {r.name}"
            if r.detail:
                line += f"  --  {r.detail}"
            print(line)
        print("-" * width)
        verdict = "ALL CHECKS PASSED" if self.all_passed else "SOME CHECKS FAILED"
        print(f"  Result: {passed_count}/{total} checks passed  --  {verdict}")
        print("=" * width + "\n")


# ---------------------------------------------------------------------------
# 1. Connect Instance Validation
# ---------------------------------------------------------------------------

class ConnectValidator:
    def __init__(self, env: str, region: str):
        self.env = env
        self.region = region
        self.client = boto3.client("connect", region_name=region)
        self.instance_id: Optional[str] = None
        self.instance_arn: Optional[str] = None
        self.expected_alias = f"westpac-ccaas-{env}"

    def find_instance(self, report: ReadinessReport):
        """List Connect instances and locate the one matching the alias pattern."""
        try:
            paginator = self.client.get_paginator("list_instances")
            for page in paginator.paginate():
                for inst in page.get("InstanceSummaryList", []):
                    if inst.get("InstanceAlias") == self.expected_alias:
                        self.instance_id = inst["Id"]
                        self.instance_arn = inst["Arn"]
                        break
                if self.instance_id:
                    break

            if self.instance_id:
                report.add(CheckResult(
                    "Connect instance found",
                    True,
                    f"alias={self.expected_alias}  id={self.instance_id}",
                ))
            else:
                report.add(CheckResult(
                    "Connect instance found",
                    False,
                    f"No instance with alias '{self.expected_alias}' found",
                ))
        except ClientError as exc:
            report.add(CheckResult("Connect instance found", False, str(exc)))

    def verify_instance_active(self, report: ReadinessReport):
        """Verify the instance status is ACTIVE."""
        if not self.instance_id:
            report.add(CheckResult("Connect instance ACTIVE", False, "Instance not found"))
            return
        try:
            resp = self.client.describe_instance(InstanceId=self.instance_id)
            status = resp["Instance"].get("InstanceStatus", "UNKNOWN")
            report.add(CheckResult(
                "Connect instance ACTIVE",
                status == "ACTIVE",
                f"status={status}",
            ))
        except ClientError as exc:
            report.add(CheckResult("Connect instance ACTIVE", False, str(exc)))

    def verify_storage_configs(self, report: ReadinessReport):
        """Verify storage configs exist for call recordings and chat transcripts."""
        if not self.instance_id:
            report.add(CheckResult("Storage configs", False, "Instance not found"))
            return

        required_types = {"CALL_RECORDINGS", "CHAT_TRANSCRIPTS"}
        found_types = set()
        try:
            for resource_type in required_types:
                resp = self.client.list_instance_storage_configs(
                    InstanceId=self.instance_id,
                    ResourceType=resource_type,
                )
                configs = resp.get("StorageConfigs", [])
                if configs:
                    found_types.add(resource_type)

            missing = required_types - found_types
            if not missing:
                report.add(CheckResult(
                    "Storage configs (recordings/transcripts)",
                    True,
                    f"found={sorted(found_types)}",
                ))
            else:
                report.add(CheckResult(
                    "Storage configs (recordings/transcripts)",
                    False,
                    f"missing={sorted(missing)}",
                ))
        except ClientError as exc:
            report.add(CheckResult("Storage configs (recordings/transcripts)", False, str(exc)))

    def verify_lambda_associations(self, report: ReadinessReport):
        """Verify at least one Lambda function is associated with the instance."""
        if not self.instance_id:
            report.add(CheckResult("Lambda associations", False, "Instance not found"))
            return
        try:
            resp = self.client.list_lambda_functions(InstanceId=self.instance_id)
            functions = resp.get("LambdaFunctions", [])
            report.add(CheckResult(
                "Lambda associations",
                len(functions) > 0,
                f"count={len(functions)}",
            ))
        except ClientError as exc:
            report.add(CheckResult("Lambda associations", False, str(exc)))

    def verify_bot_associations(self, report: ReadinessReport):
        """Verify at least one Lex bot is associated with the instance."""
        if not self.instance_id:
            report.add(CheckResult("Bot associations", False, "Instance not found"))
            return
        try:
            # Try V2 bots first, fall back to V1
            try:
                resp = self.client.list_bots(
                    InstanceId=self.instance_id,
                    LexVersion="V2",
                )
                bots = resp.get("LexBots", [])
            except ClientError:
                resp = self.client.list_bots(
                    InstanceId=self.instance_id,
                    LexVersion="V1",
                )
                bots = resp.get("LexBots", [])

            report.add(CheckResult(
                "Bot associations",
                len(bots) > 0,
                f"count={len(bots)}",
            ))
        except ClientError as exc:
            report.add(CheckResult("Bot associations", False, str(exc)))

    def run_all(self, report: ReadinessReport):
        logger.info("Validating Connect instance '%s' ...", self.expected_alias)
        self.find_instance(report)
        self.verify_instance_active(report)
        self.verify_storage_configs(report)
        self.verify_lambda_associations(report)
        self.verify_bot_associations(report)


# ---------------------------------------------------------------------------
# 2. Infrastructure Validation
# ---------------------------------------------------------------------------

class InfraValidator:
    """Validates S3, DynamoDB, KMS, and Kinesis resources."""

    def __init__(self, env: str, region: str):
        self.env = env
        self.region = region
        self.project = "westpac-ccaas"
        self.s3 = boto3.client("s3", region_name=region)
        self.dynamodb = boto3.client("dynamodb", region_name=region)
        self.kms = boto3.client("kms", region_name=region)
        self.kinesis = boto3.client("kinesis", region_name=region)

    # -- S3 -----------------------------------------------------------------

    def _check_bucket(self, bucket_name: str, report: ReadinessReport):
        # Existence
        try:
            self.s3.head_bucket(Bucket=bucket_name)
        except ClientError:
            report.add(CheckResult(f"S3 bucket exists: {bucket_name}", False, "Bucket not found"))
            return

        report.add(CheckResult(f"S3 bucket exists: {bucket_name}", True))

        # Encryption
        try:
            enc = self.s3.get_bucket_encryption(Bucket=bucket_name)
            rules = enc.get("ServerSideEncryptionConfiguration", {}).get("Rules", [])
            encrypted = any(
                r.get("ApplyServerSideEncryptionByDefault", {}).get("SSEAlgorithm")
                for r in rules
            )
            report.add(CheckResult(
                f"S3 encryption: {bucket_name}",
                encrypted,
                f"rules={len(rules)}",
            ))
        except ClientError as exc:
            report.add(CheckResult(f"S3 encryption: {bucket_name}", False, str(exc)))

    def validate_s3(self, report: ReadinessReport):
        expected_buckets = [
            f"{self.project}-call-recordings-{self.env}",
            f"{self.project}-chat-transcripts-{self.env}",
            f"{self.project}-terraform-state-{self.env}",
        ]
        for bucket in expected_buckets:
            self._check_bucket(bucket, report)

    # -- DynamoDB -----------------------------------------------------------

    def validate_dynamodb(self, report: ReadinessReport):
        expected_tables = [
            f"{self.project}-terraform-locks-{self.env}",
            f"{self.project}-contact-metadata-{self.env}",
        ]
        for table_name in expected_tables:
            try:
                resp = self.dynamodb.describe_table(TableName=table_name)
                status = resp["Table"].get("TableStatus", "UNKNOWN")
                report.add(CheckResult(
                    f"DynamoDB table exists: {table_name}",
                    status == "ACTIVE",
                    f"status={status}",
                ))
            except ClientError:
                report.add(CheckResult(
                    f"DynamoDB table exists: {table_name}",
                    False,
                    "Table not found",
                ))
                continue

            # PITR
            try:
                pitr = self.dynamodb.describe_continuous_backups(TableName=table_name)
                pitr_status = (
                    pitr.get("ContinuousBackupsDescription", {})
                    .get("PointInTimeRecoveryDescription", {})
                    .get("PointInTimeRecoveryStatus", "DISABLED")
                )
                report.add(CheckResult(
                    f"DynamoDB PITR: {table_name}",
                    pitr_status == "ENABLED",
                    f"pitr={pitr_status}",
                ))
            except ClientError as exc:
                report.add(CheckResult(f"DynamoDB PITR: {table_name}", False, str(exc)))

    # -- KMS ----------------------------------------------------------------

    def validate_kms(self, report: ReadinessReport):
        alias_prefix = f"alias/{self.project}-{self.env}"
        try:
            paginator = self.kms.get_paginator("list_aliases")
            matched_keys = []
            for page in paginator.paginate():
                for alias in page.get("Aliases", []):
                    if alias.get("AliasName", "").startswith(alias_prefix):
                        key_id = alias.get("TargetKeyId")
                        if key_id:
                            matched_keys.append((alias["AliasName"], key_id))

            if not matched_keys:
                report.add(CheckResult(
                    "KMS keys found",
                    False,
                    f"No aliases matching '{alias_prefix}*'",
                ))
                return

            report.add(CheckResult(
                "KMS keys found",
                True,
                f"count={len(matched_keys)}",
            ))

            for alias_name, key_id in matched_keys:
                try:
                    key_meta = self.kms.describe_key(KeyId=key_id)["KeyMetadata"]
                    enabled = key_meta.get("Enabled", False)
                    report.add(CheckResult(
                        f"KMS key enabled: {alias_name}",
                        enabled,
                        f"key_id={key_id}",
                    ))
                except ClientError as exc:
                    report.add(CheckResult(f"KMS key enabled: {alias_name}", False, str(exc)))

                try:
                    rotation = self.kms.get_key_rotation_status(KeyId=key_id)
                    rotating = rotation.get("KeyRotationEnabled", False)
                    report.add(CheckResult(
                        f"KMS key rotation: {alias_name}",
                        rotating,
                        f"rotation_enabled={rotating}",
                    ))
                except ClientError as exc:
                    report.add(CheckResult(f"KMS key rotation: {alias_name}", False, str(exc)))

        except ClientError as exc:
            report.add(CheckResult("KMS keys found", False, str(exc)))

    # -- Kinesis ------------------------------------------------------------

    def validate_kinesis(self, report: ReadinessReport):
        expected_streams = [
            f"{self.project}-ctr-stream-{self.env}",
            f"{self.project}-agent-events-{self.env}",
        ]
        for stream_name in expected_streams:
            try:
                resp = self.kinesis.describe_stream_summary(StreamName=stream_name)
                status = resp["StreamDescriptionSummary"].get("StreamStatus", "UNKNOWN")
                report.add(CheckResult(
                    f"Kinesis stream ACTIVE: {stream_name}",
                    status == "ACTIVE",
                    f"status={status}",
                ))
            except ClientError:
                report.add(CheckResult(
                    f"Kinesis stream ACTIVE: {stream_name}",
                    False,
                    "Stream not found",
                ))

    def run_all(self, report: ReadinessReport):
        logger.info("Validating infrastructure resources ...")
        self.validate_s3(report)
        self.validate_dynamodb(report)
        self.validate_kms(report)
        self.validate_kinesis(report)


# ---------------------------------------------------------------------------
# 3. IVR Flow Simulation
# ---------------------------------------------------------------------------

class IVRFlowSimulator:
    """
    Simulates an IVR interaction by creating a test chat contact, sending a
    message to trigger the Lex bot, validating the bot responds, and then
    disconnecting the contact.
    """

    def __init__(self, instance_id: Optional[str], region: str):
        self.instance_id = instance_id
        self.region = region
        self.client = boto3.client("connect", region_name=region)
        self.participant_client = boto3.client(
            "connectparticipant", region_name=region
        )

    def simulate_ivr_flow(self, report: ReadinessReport):
        """End-to-end chat contact simulation."""
        if not self.instance_id:
            report.add(CheckResult(
                "IVR flow simulation",
                False,
                "Skipped -- Connect instance not found",
            ))
            return

        contact_id = None
        participant_token = None

        try:
            # ----- Step 1: Discover a contact flow to use for testing ------
            contact_flow_id = self._find_test_contact_flow()
            if not contact_flow_id:
                report.add(CheckResult(
                    "IVR flow simulation - contact flow lookup",
                    False,
                    "No suitable contact flow found for testing",
                ))
                return

            report.add(CheckResult(
                "IVR flow simulation - contact flow lookup",
                True,
                f"flow_id={contact_flow_id}",
            ))

            # ----- Step 2: Start a chat contact ----------------------------
            start_resp = self.client.start_chat_contact(
                InstanceId=self.instance_id,
                ContactFlowId=contact_flow_id,
                ParticipantDetails={"DisplayName": "ReadinessValidator"},
                InitialMessage={
                    "ContentType": "text/plain",
                    "Content": "hello",
                },
            )
            contact_id = start_resp.get("ContactId")
            participant_token = start_resp.get("ParticipantToken")

            if not contact_id or not participant_token:
                report.add(CheckResult(
                    "IVR flow simulation - start chat",
                    False,
                    "Missing ContactId or ParticipantToken in response",
                ))
                return

            report.add(CheckResult(
                "IVR flow simulation - start chat",
                True,
                f"contact_id={contact_id}",
            ))

            # ----- Step 3: Create participant connection -------------------
            conn_resp = self.participant_client.create_participant_connection(
                ParticipantToken=participant_token,
                Type=["CONNECTION_CREDENTIALS"],
            )
            connection_token = conn_resp.get("ConnectionCredentials", {}).get(
                "ConnectionToken"
            )
            if not connection_token:
                report.add(CheckResult(
                    "IVR flow simulation - participant connection",
                    False,
                    "No ConnectionToken returned",
                ))
                return

            report.add(CheckResult(
                "IVR flow simulation - participant connection",
                True,
            ))

            # ----- Step 4: Send a test message to trigger the Lex bot ------
            self.participant_client.send_message(
                ConnectionToken=connection_token,
                ContentType="text/plain",
                Content="I need help with my account",
            )
            report.add(CheckResult(
                "IVR flow simulation - send test message",
                True,
            ))

            # ----- Step 5: Wait briefly and retrieve transcript ------------
            time.sleep(3)
            transcript_resp = self.participant_client.get_transcript(
                ConnectionToken=connection_token,
                SortOrder="ASCENDING",
                MaxResults=10,
            )
            items = transcript_resp.get("Transcript", [])
            bot_replied = any(
                item.get("ParticipantRole") in ("SYSTEM", "AGENT")
                for item in items
            )
            report.add(CheckResult(
                "IVR flow simulation - bot response received",
                bot_replied,
                f"transcript_items={len(items)}",
            ))

            # ----- Step 6: Disconnect the contact --------------------------
            self.participant_client.disconnect_participant(
                ConnectionToken=connection_token,
            )
            report.add(CheckResult(
                "IVR flow simulation - disconnect",
                True,
            ))

        except ClientError as exc:
            error_code = exc.response["Error"]["Code"]
            report.add(CheckResult(
                "IVR flow simulation",
                False,
                f"{error_code}: {exc.response['Error']['Message']}",
            ))
        except Exception as exc:
            report.add(CheckResult(
                "IVR flow simulation",
                False,
                f"Unexpected error: {exc}",
            ))

    def _find_test_contact_flow(self) -> Optional[str]:
        """Return the ID of the first CONTACT_FLOW of type CONTACT_FLOW."""
        try:
            paginator = self.client.get_paginator("list_contact_flows")
            for page in paginator.paginate(
                InstanceId=self.instance_id,
                ContactFlowTypes=["CONTACT_FLOW"],
            ):
                for flow in page.get("ContactFlowSummaryList", []):
                    # Prefer a flow whose name contains 'test' or 'sample';
                    # otherwise return the first available one.
                    name = (flow.get("Name") or "").lower()
                    if "test" in name or "sample" in name or "default" in name:
                        return flow["Id"]
                # Fallback: return first flow from the page
                flows = page.get("ContactFlowSummaryList", [])
                if flows:
                    return flows[0]["Id"]
        except ClientError:
            pass
        return None


# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------

def parse_args(argv=None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Westpac CCaaS Amazon Connect readiness validator",
    )
    parser.add_argument(
        "--environment",
        required=True,
        help="Target environment name (e.g. dev, uat, prod)",
    )
    parser.add_argument(
        "--region",
        default="ap-southeast-2",
        help="AWS region (default: ap-southeast-2)",
    )
    return parser.parse_args(argv)


def main(argv=None) -> int:
    args = parse_args(argv)
    env = args.environment
    region = args.region

    logger.info(
        "Starting readiness validation  env=%s  region=%s", env, region
    )

    report = ReadinessReport()

    # 1. Connect instance
    connect_validator = ConnectValidator(env, region)
    connect_validator.run_all(report)

    # 2. Infrastructure
    infra_validator = InfraValidator(env, region)
    infra_validator.run_all(report)

    # 3. IVR flow simulation
    ivr_sim = IVRFlowSimulator(connect_validator.instance_id, region)
    ivr_sim.simulate_ivr_flow(report)

    # 4. Report
    report.print_report()

    return 0 if report.all_passed else 1


if __name__ == "__main__":
    sys.exit(main())
