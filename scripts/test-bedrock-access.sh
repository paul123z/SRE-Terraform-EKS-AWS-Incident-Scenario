#!/bin/bash

# Test Bedrock Access Script
# This script verifies if Bedrock models are accessible

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

# Configuration
AWS_REGION="us-east-1"  # Bedrock is available in us-east-1
MODEL_ID="anthropic.claude-3-sonnet-20240229-v1:0"

print_header "================================
BEDROCK ACCESS TEST
================================"

print_status "Checking AWS credentials..."
if aws sts get-caller-identity &> /dev/null; then
    print_success "AWS credentials verified"
else
    print_error "AWS credentials not configured"
    exit 1
fi

print_status "Testing Bedrock model access..."
print_status "Region: $AWS_REGION"
print_status "Model: $MODEL_ID"

# Test 1: List available models
print_status "Step 1: Listing available models..."
if aws bedrock list-foundation-models --region "$AWS_REGION" --query "modelSummaries[?modelId=='$MODEL_ID']" --output table 2>/dev/null; then
    print_success "Model found in catalog"
else
    print_error "Failed to list models or model not found"
    exit 1
fi

# Test 2: Check model access
print_status "Step 2: Checking model access..."
if aws bedrock get-foundation-model --model-id "$MODEL_ID" --region "$AWS_REGION" &>/dev/null; then
    print_success "Model access verified"
else
    print_error "Model access denied"
    print_warning "You need to request model access in the AWS Bedrock console"
    print_status "Go to: https://console.aws.amazon.com/bedrock/"
    print_status "Click 'Request model access' for Anthropic's Claude"
    exit 1
fi

# Test 3: Simple inference test
print_status "Step 3: Testing simple inference..."
TEST_PROMPT='{"prompt": "Hello, this is a test. Please respond with just: SUCCESS", "max_tokens": 50}'

if aws bedrock invoke-model \
    --model-id "$MODEL_ID" \
    --body "$TEST_PROMPT" \
    --region "$AWS_REGION" \
    --content-type application/json \
    /tmp/bedrock_test_response.json 2>/dev/null; then
    
    print_success "Bedrock inference test successful!"
    print_status "Response preview:"
    cat /tmp/bedrock_test_response.json | head -3
    echo ""
    
    # Clean up
    rm -f /tmp/bedrock_test_response.json
    
    print_success "🎉 Bedrock is fully configured and working!"
    print_status "You can now use real AI analysis in your incident demo"
    
else
    print_error "Bedrock inference test failed"
    print_warning "Model access might not be fully enabled yet"
    print_status "Please wait a few minutes and try again"
    exit 1
fi

print_header "================================
NEXT STEPS
================================"
print_status "Now you can run the incident demo with real AI analysis:"
print_status "1. ./scripts/incident-demo.sh"
print_status "2. The AI analysis will use Bedrock instead of fallback"
print_status "3. You'll get real AI-powered incident analysis!" 