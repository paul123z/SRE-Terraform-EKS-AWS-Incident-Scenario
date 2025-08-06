aws bedrock-runtime invoke-model \
  --region us-west-1 \
  --cli-binary-format raw-in-base64-out \
  --model-id us.anthropic.claude-sonnet-4-20250514-v1:0 \
  --content-type application/json \
  --accept application/json \
  --body '{
    "anthropic_version": "bedrock-2023-05-31",
    "messages": [
      {
        "role": "user",
        "content": "Explain Kubernetes like I am five."
      }
    ],
    "temperature": 0.7,
    "max_tokens": 500
  }' \
  response.json
