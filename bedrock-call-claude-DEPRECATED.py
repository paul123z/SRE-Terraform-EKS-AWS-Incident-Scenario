import boto3
import json

client = boto3.client("bedrock-runtime", region_name="us-west-1")

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
    "inference_profile_arn": "arn:aws:bedrock:us-west-1:462738742234:inference-profile/us.anthropic.claude-sonnet-4-20250514-v1:0"
}

response = client.invoke_model(
    modelId="us.anthropic.claude-sonnet-4-20250514-v1:0",
    contentType="application/json",
    accept="application/json",
    body=json.dumps(body)
)

print("✅ Claude Sonnet 4 Response:")
print(response["body"].read().decode())
