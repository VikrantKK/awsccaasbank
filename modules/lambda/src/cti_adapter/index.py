"""CTI Adapter integration function for Amazon Connect.

Handles CTI events from the Amazon Connect contact flow,
processes agent and contact state changes, and persists
interaction data to DynamoDB.
"""

import json
import logging
import os

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

DYNAMODB_CONTACT_TABLE = os.environ.get("DYNAMODB_CONTACT_TABLE", "")
DYNAMODB_SESSION_TABLE = os.environ.get("DYNAMODB_SESSION_TABLE", "")
CONNECT_INSTANCE_ID = os.environ.get("CONNECT_INSTANCE_ID", "")
ENVIRONMENT = os.environ.get("ENVIRONMENT", "dev")

dynamodb = boto3.resource("dynamodb", region_name="ap-southeast-2")


def handler(event, context):
    """Lambda entry point for CTI adapter events.

    Args:
        event: CTI event payload from Amazon Connect.
        context: Lambda execution context.

    Returns:
        dict: HTTP-style response with status code and body.
    """
    logger.info("CTI adapter invoked: request_id=%s", context.aws_request_id)
    logger.info("Event: %s", json.dumps(event, default=str))

    try:
        contact_id = event.get("Details", {}).get("ContactData", {}).get("ContactId", "unknown")

        logger.info("Processing contact: %s", contact_id)

        if DYNAMODB_CONTACT_TABLE:
            table = dynamodb.Table(DYNAMODB_CONTACT_TABLE)
            table.put_item(
                Item={
                    "ContactId": contact_id,
                    "Environment": ENVIRONMENT,
                    "ConnectInstanceId": CONNECT_INSTANCE_ID,
                    "EventPayload": json.dumps(event, default=str),
                }
            )
            logger.info("Contact record persisted: %s", contact_id)

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "CTI event processed successfully",
                "contactId": contact_id,
            }),
        }

    except Exception:
        logger.exception("Error processing CTI event")
        return {
            "statusCode": 500,
            "body": json.dumps({"message": "Internal server error"}),
        }
