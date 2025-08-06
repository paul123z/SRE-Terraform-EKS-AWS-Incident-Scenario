import boto3
import json

# Create the Bedrock runtime client
client = boto3.client("bedrock-runtime", region_name="us-west-1")

# Replace this with your actual system-provided inference profile ARN
inference_profile_arn = "arn:aws:bedrock:us-west-1:462738742234:inference-profile/us.anthropic.claude-sonnet-4-20250514-v1:0"

# Construct the body of the request
body = {
    "anthropic_version": "bedrock-2023-05-31",
    "messages": [
        {
            "role": "user",
            "content": "Explain Kubernetes like I'm five."
        }
    ],
    "temperature": 0.7,
    "max_tokens": 500,
    "inference_profile_arn": inference_profile_arn  # ✅ This must be camelCase (confirmed)
}

# Send the request
response = client.invoke_model(
    modelId="us.anthropic.claude-sonnet-4-20250514-v1:0",
    contentType="application/json",
    accept="application/json",
    body=json.dumps(body)
)

# Print the model's response
print("✅ Claude Sonnet 4 Response:")
print(response["body"].read().decode())
