# IMPORTANT unless you want Lizzo hell
# App Client MUST NOT have a client secret enabled


import boto3
import getpass
import json

# =========================
# Configuration
# =========================

CLIENT_ID = "REPLACE_WITH_CLIENT_ID"
REGION = "us-east-1"

# =========================
# User Input
# =========================

username = input("Username: ")
password = getpass.getpass("Password: ")

# =========================
# Cognito Client
# =========================

client = boto3.client("cognito-idp", region_name=REGION)

try:
    response = client.initiate_auth(
        ClientId=CLIENT_ID,
        AuthFlow="USER_PASSWORD_AUTH",
        AuthParameters={
            "USERNAME": username,
            "PASSWORD": password
        }
    )

    # =========================
    # Handle MFA Challenge
    # =========================

    if response.get("ChallengeName") == "SMS_MFA":
        code = input("Enter MFA Code: ")

        response = client.respond_to_auth_challenge(
            ClientId=CLIENT_ID,
            ChallengeName="SMS_MFA",
            Session=response["Session"],
            ChallengeResponses={
                "USERNAME": username,
                "SMS_MFA_CODE": code
            }
        )

    # =========================
    # Extract Tokens
    # =========================

    auth = response["AuthenticationResult"]

    print("\n========== TOKENS ==========\n")

    print("Access Token:\n")
    print(auth["AccessToken"])

    print("\n============================\n")

except Exception as e:
    print("\nAuthentication Failed\n")
    print(str(e))

    import uuid
from datetime import datetime

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("token-tracking")

token_id = str(uuid.uuid4())

table.put_item(
    Item={
        "token_id": token_id,
        "username": username,
        "issued_at": datetime.utcnow().isoformat(),
        "used": False
    }
)