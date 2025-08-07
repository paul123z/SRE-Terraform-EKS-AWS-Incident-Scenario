#!/bin/bash

# Simple Lambda test script

echo "Testing Lambda function..."

# Create a simple payload
cat > test-payload.json << EOF
{
  "incident_id": "test-incident",
  "incident_type": "memory_leak",
  "time_range_minutes": 30
}
EOF

echo "Payload created:"
cat test-payload.json

echo ""
echo "Invoking Lambda function..."

# Invoke Lambda function
aws lambda invoke \
  --function-name sre-incident-demo-incident-analyzer \
  --region eu-central-1 \
  --payload file://test-payload.json \
  response.json

echo ""
echo "Response:"
cat response.json

echo ""
echo "Cleaning up..."
rm -f test-payload.json response.json
