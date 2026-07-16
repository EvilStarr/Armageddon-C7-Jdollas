# import boto3
# import os
# import time

# dynamodb = boto3.resource("dynamodb")
# table = dynamodb.Table(os.environ["TOKEN_TABLE"])

# # how long an unused record sticks around before DynamoDB TTL cleans it up
# RECORD_TTL_SECONDS = 24 * 60 * 60


# def lambda_handler(event, context):
#     """
#     Cognito Post Authentication trigger.
#     Fires after a successful login, before tokens are handed back
#     to the client. Writes one row per session so we can later check
#     whether the issued token was ever actually used against the API.
#     """
#     sub = event["request"]["userAttributes"]["sub"]
#     issued_at = int(time.time())
#     token_id = f"{sub}#{issued_at}"

#     table.put_item(
#         Item={
#             "token_id": token_id,
#             "sub": sub,
#             "issued_at": issued_at,
#             "used": False,
#             "expires_at": issued_at + RECORD_TTL_SECONDS,
#         }
#     )

#     print(f"Logged issued token {token_id}")

#     # Post Authentication triggers must return the event unchanged
#     return event
