#!/bin/bash

# Fix Bedrock Permissions Script
# This script adds the missing Bedrock permissions to the Lambda role

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_header() {
    echo -e "${YELLOW}$1${NC}"
}

print_header "================================
FIXING BEDROCK PERMISSIONS
================================"

print_status "Adding Bedrock permissions to Lambda role for us-west-1 access..."

# Create the Bedrock policy document
BEDROCK_POLICY='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel"
      ],
      "Resource": [
        "arn:aws:bedrock:us-west-1::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0"
      ]
    }
  ]
}'

# Add the policy to the Lambda role
if /usr/local/aws-cli/v2/current/bin/aws iam put-role-policy \
    --role-name sre-incident-demo-incident-analyzer-lambda \
    --policy-name bedrock-us-west-1-policy \
    --policy-document "$BEDROCK_POLICY" \
    --region eu-central-1; then
    
    print_success "Bedrock permissions added successfully!"
    print_status "Lambda can now access Bedrock in us-west-1"
    
else
    print_error "Failed to add Bedrock permissions"
    exit 1
fi

print_header "================================
TESTING BEDROCK ACCESS
================================"
print_status "Now let's test if Bedrock is working..."

# Test the Lambda function
if ./scripts/test-bedrock-lambda.sh; then
    print_success "🎉 Bedrock is now working!"
    print_status "You can run the full incident demo with real AI analysis"
else
    print_warning "Bedrock test failed - let's check the logs"
fi

print_header "================================
NEXT STEPS
================================"
print_status "If Bedrock is working, run the full demo:"
print_status "./scripts/incident-demo.sh" 