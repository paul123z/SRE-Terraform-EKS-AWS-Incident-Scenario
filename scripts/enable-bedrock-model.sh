#!/bin/bash

# Enable Bedrock Model Access Script
# This script helps you enable Bedrock model access

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
BEDROCK MODEL ACCESS SETUP
================================"

print_status "You have generated an API key, but you still need to enable model access."
echo ""

print_header "STEP 1: Enable Model Access"
print_status "1. Go to: https://console.aws.amazon.com/bedrock/"
print_status "2. Click 'Model catalog' in the left sidebar"
print_status "3. Find 'Anthropic Claude 3 Sonnet'"
print_status "4. Click 'Request model access'"
print_status "5. Accept the terms and submit"
print_status "6. Wait for approval (usually instant)"
echo ""

print_header "STEP 2: Test Current Setup"
print_status "Let's test if the API key is working..."

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
    print_success "Loaded .env file"
else
    print_error ".env file not found"
    exit 1
fi

# Test API key
if [ -n "$AWS_BEARER_TOKEN_BEDROCK" ]; then
    print_success "API key is set: ${AWS_BEARER_TOKEN_BEDROCK:0:20}..."
else
    print_error "API key not found in .env"
    exit 1
fi

print_header "STEP 3: Test Bedrock Access"
print_status "Testing with API key..."

# Test using curl with API key
TEST_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $AWS_BEARER_TOKEN_BEDROCK" \
    -d '{"prompt": "Hello, this is a test", "max_tokens": 50}' \
    "https://bedrock-runtime.us-east-1.amazonaws.com/invoke-model?modelId=anthropic.claude-3-sonnet-20240229-v1:0" 2>/dev/null || echo "FAILED")

if [[ "$TEST_RESPONSE" == *"FAILED"* ]]; then
    print_warning "API key test failed - this might be normal if model access isn't enabled yet"
    print_status "Continue with Step 1 to enable model access"
else
    print_success "API key is working!"
    print_status "Response preview: ${TEST_RESPONSE:0:100}..."
fi

echo ""
print_header "STEP 4: After Enabling Model Access"
print_status "Once you've enabled model access, test again with:"
print_status "./scripts/test-bedrock-lambda.sh"
echo ""
print_status "Then run the full demo with real AI:"
print_status "./scripts/incident-demo.sh"

print_header "================================
SUMMARY
================================"
print_status "✅ API Key: Generated and stored in .env"
print_status "⏳ Model Access: Needs to be enabled in AWS console"
print_status "🎯 Next: Enable model access, then test again" 