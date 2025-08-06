#!/bin/bash

aws bedrock-runtime invoke-model \
    --region us-east-1 \
    --model-id "amazon.nova-lite-2024-05-20-v1:0" \
    --content-type "application/json" \
    --body '{"inputText": "Hello! Test message", "maxTokens": 50, "temperature": 0.7, "topP": 0.9}' \
    --cli-binary-format raw-in-base64-out \
    response.json