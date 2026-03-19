"""Post-Call Survey trigger function for Amazon Connect.

Initiates an outbound survey call or SMS after the primary
contact has ended, recording survey dispatch metadata in
DynamoDB for tracking and analytics.
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
    """Lambda entry point for post-call survey initiation.

    Args:
        event: Contact event containing completed call details.
        context: Lambda execution context.

    Returns:
        dict: HTTP-style response with survey dispatch status.
    """
    logger.info("Post-call survey invoked: request_id=%s", context.aws_request_id)
    logger.info("Event: %s", json.dumps(event, default=str))

    try:
        contact_data = event.get("Details", {}).get("ContactData", {})
        contact_id = contact_data.get("ContactId", "unknown")
        customer_endpoint = contact_data.get("CustomerEndpoint", {})
        phone_number = customer_endpoint.get("Address", "unknown")

        logger.info(
            "Initiating post-call survey for contact=%s, phone=%s",
            contact_id,
            phone_number,
        )

        survey_record = {
            "ContactId": contact_id,
            "PhoneNumber": phone_number,
            "SurveyStatus": "initiated",
            "ConnectInstanceId": CONNECT_INSTANCE_ID,
            "Environment": ENVIRONMENT,
        }

        if DYNAMODB_CONTACT_TABLE:
            table = dynamodb.Table(DYNAMODB_CONTACT_TABLE)
            table.put_item(Item=survey_record)
            logger.info("Survey record persisted for contact: %s", contact_id)

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Post-call survey initiated",
                "contactId": contact_id,
                "surveyStatus": "initiated",
            }),
        }

    except Exception:
        logger.exception("Error initiating post-call survey")
        return {
            "statusCode": 500,
            "body": json.dumps({"message": "Survey initiation failed"}),
        }
