# import boto3
# import os
# import time

# dynamodb = boto3.resource("dynamodb")
# table = dynamodb.Table(os.environ["TOKEN_TABLE"])

# # tokens older than this, and still unused, get flagged
# STALE_AFTER_SECONDS = int(os.environ.get("STALE_AFTER_SECONDS", "900"))  # 15 min


# def lambda_handler(event, context):
#     print("Scanning token_tracking for unused tokens...")

#     cutoff = int(time.time()) - STALE_AFTER_SECONDS

#     # small table -> scan is fine; move to a GSI on `used` if this grows
#     response = table.scan(
#         FilterExpression=(
#             "used_ = :f AND issued_at < :cutoff "
#             "AND attribute_not_exists(flagged)"
#         ),
#         ExpressionAttributeNames={"used_": "used"},
#         ExpressionAttributeValues={":f": False, ":cutoff": cutoff},
#     )

#     stale_tokens = response.get("Items", [])

#     for item in stale_tokens:
#         print(
#             f"UNUSED TOKEN FLAGGED: sub={item['sub']} "
#             f"token_id={item['token_id']} issued_at={item['issued_at']}"
#         )
#         # mark as reviewed so it doesn't get re-flagged every 5 minutes
#         table.update_item(
#             Key={"token_id": item["token_id"]},
#             UpdateExpression="SET flagged = :t",
#             ExpressionAttributeValues={":t": True},
#         )

#     print(f"Done. {len(stale_tokens)} unused token(s) flagged.")

#     return {
#         "statusCode": 200,
#         "unused_tokens_flagged": len(stale_tokens),
#     }
