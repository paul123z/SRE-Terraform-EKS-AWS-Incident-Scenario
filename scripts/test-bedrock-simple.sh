#!/bin/bash

# Simple Amazon Bedrock Test Script
# Tests basic Bedrock access with a simple prompt

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

print_info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

main() {
    print_header "SIMPLE BEDROCK TEST"
    
    print_info "Testing Amazon Bedrock access with a simple prompt..."
    
    # Test 1: Check if AWS CLI is configured
    print_info "Checking AWS CLI configuration..."
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        print_error "AWS CLI not configured. Please run 'aws configure' first."
        exit 1
    fi
    print_success "AWS CLI is configured"
    
    # Test 2: Try to list available models
    print_info "Listing available Bedrock models in us-west-1..."
    if aws bedrock list-foundation-models --region us-west-1 --query "modelSummaries[?providerName=='Anthropic'].{modelId: modelId, modelName: modelName}" --output table 2>/dev/null; then
        print_success "Successfully listed Bedrock models"
    else
        print_warning "Could not list models - this might be normal if models are not enabled"
    fi
    
    # Test 3: Simple Bedrock invocation
    print_info "Testing Bedrock invocation with a simple prompt..."
    
    # Create a simple test payload
    TEST_PAYLOAD='{
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 100,
        "messages": [
            {
                "role": "user",
                "content": "Say hello and confirm you are working. Keep it very short."
            }
        ]
    }'
    
    # Try to invoke Bedrock
    print_info "Invoking Bedrock with test payload..."
    
    RESPONSE=$(aws bedrock-runtime invoke-model \
        --model-id "anthropic.claude-3-sonnet-20240229-v1:0" \
        --region us-west-1 \
        --body "$TEST_PAYLOAD" \
        --cli-binary-format raw-in-base64-out \
        --output json 2>&1)
    
    if [ $? -eq 0 ]; then
        print_success "Bedrock invocation successful!"
        echo ""
        print_info "Response:"
        echo "$RESPONSE" | jq -r '.content[0].text' 2>/dev/null || echo "$RESPONSE"
    else
        print_error "Bedrock invocation failed"
        echo "Error details: $RESPONSE"
        
        # Try alternative model ID
        print_info "Trying alternative model ID..."
        RESPONSE2=$(aws bedrock-runtime invoke-model \
            --model-id "anthropic.claude-sonnet-4-20250514-v1:0" \
            --region us-west-1 \
            --body "$TEST_PAYLOAD" \
            --cli-binary-format raw-in-base64-out \
            --output json 2>&1)
        
        if [ $? -eq 0 ]; then
            print_success "Bedrock invocation successful with alternative model!"
            echo ""
            print_info "Response:"
            echo "$RESPONSE2" | jq -r '.content[0].text' 2>/dev/null || echo "$RESPONSE2"
        else
            print_error "Both model IDs failed"
            echo "Error details: $RESPONSE2"
        fi
    fi
    
    echo ""
    print_header "TEST COMPLETE"
    print_info "If you see a response above, Bedrock is working!"
    print_info "If you see errors, check your Bedrock model access in AWS Console."
}

main "$@" 