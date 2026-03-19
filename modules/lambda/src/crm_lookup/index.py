"""CRM Lookup function for Amazon Connect.

Performs customer lookups by phone number during inbound calls,
returning customer profile data to the contact flow for
personalised routing and agent screen-pop.
"""

import json
import logging
import os

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

DYNAMODB_CONTACT_TABLE = os.environ.get("DYNAMODB_CONTACT_TABLE", "")
DYNAMODB_SESSION_TABLE = os.environ.get("DYNAMODB_SESSION_TABLE", "")
ENVIRONMENT = os.environ.get("ENVIRONMENT", "dev")

dynamodb = boto3.resource("dynamodb", region_name="ap-southeast-2")


def handler(event, context):
    """Lambda entry point for CRM customer lookup.

    Args:
        event: Contact flow event containing customer phone number.
        context: Lambda execution context.

    Returns:
        dict: Customer profile data for the contact flow.
    """
    logger.info("CRM lookup invoked: request_id=%s", context.aws_request_id)
    logger.info("Event: %s", json.dumps(event, default=str))

    try:
        contact_data = event.get("Details", {}).get("ContactData", {})
        customer_endpoint = contact_data.get("CustomerEndpoint", {})
        phone_number = customer_endpoint.get("Address", "unknown")

        logger.info("Looking up customer by phone: %s", phone_number)

        # Mock customer data — replace with real CRM integration
        customer = {
            "customerFound": "true",
            "customerId": "CUST-001234",
            "firstName": "Jane",
            "lastName": "Smith",
            "segment": "premium",
            "accountStatus": "active",
            "preferredLanguage": "en-AU",
            "phoneNumber": phone_number,
        }

        logger.info("Customer found: %s", customer["customerId"])

        if DYNAMODB_SESSION_TABLE:
            table = dynamodb.Table(DYNAMODB_SESSION_TABLE)
            table.put_item(
                Item={
                    "SessionId": contact_data.get("ContactId", "unknown"),
                    "PhoneNumber": phone_number,
                    "CustomerId": customer["customerId"],
                    "Environment": ENVIRONMENT,
                }
            )

        return customer

    except Exception:
        logger.exception("Error during CRM lookup")
        return {
            "customerFound": "false",
            "errorMessage": "CRM lookup failed",
        }
