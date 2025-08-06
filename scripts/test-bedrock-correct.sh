#!/bin/bash

# Correct Amazon Bedrock Test Script
# Uses the proper syntax as recommended by Amazon Bedrock

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
    print_header "CORRECT BEDROCK TEST"
    
    print_info "Testing Amazon Bedrock with correct syntax..."
    
    # Test 1: Check if AWS CLI is configured
    print_info "Checking AWS CLI configuration..."
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        print_error "AWS CLI not configured. Please run 'aws configure' first."
        exit 1
    fi
    print_success "AWS CLI is configured"
    
    # Test 2: Check model status
    print_info "Checking Claude Sonnet 4 model status..."
    MODEL_STATUS=$(aws bedrock get-foundation-model --model-identifier "anthropic.claude-sonnet-4-20250514-v1:0" --region us-east-1 --query 'modelDetails.modelLifecycle.status' --output text 2>/dev/null)
    
    if [ "$MODEL_STATUS" = "ACTIVE" ]; then
        print_success "Model is ACTIVE - ready for invocation"
    else
        print_warning "Model status is: $MODEL_STATUS"
        print_warning "You need to enable model access in AWS Console"
        print_info "Go to: https://console.aws.amazon.com/bedrock/"
        print_info "Click 'Model access' and request access for Claude Sonnet 4"
        exit 1
    fi
    
    # Test 3: Test Bedrock invocation with correct syntax
    print_info "Testing Bedrock invocation with correct syntax..."
    
    # Create output file with timestamp
    OUTPUT_FILE="bedrock-test-$(date +%Y%m%d-%H%M%S).json"
    
    # Use the correct invocation syntax for Claude Sonnet 4
    RESPONSE=$(aws bedrock-runtime invoke-model \
        --region us-east-1 \
        --model-id "anthropic.claude-sonnet-4-20250514-v1:0" \
        --content-type "application/json" \
        --body '{
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 100,
            "messages": [
                {
                    "role": "user",
                    "content": "Hello! Can you confirm that Bedrock is working? Please respond briefly."
                }
            ]
        }' \
        "$OUTPUT_FILE" 2>&1)
    
    if [ $? -eq 0 ]; then
        print_success "Bedrock invocation successful!"
        echo ""
        print_info "Response saved to: $OUTPUT_FILE"
        print_info "Response content:"
        cat "$OUTPUT_FILE" | jq -r '.content[0].text' 2>/dev/null || cat "$OUTPUT_FILE"
    else
        print_error "Bedrock invocation failed"
        echo "Error details: $RESPONSE"
        
        # Check if it's a model access issue
        if echo "$RESPONSE" | grep -q "AccessDenied\|ValidationException\|model access"; then
            print_warning "This looks like a model access issue"
            print_info "Please enable model access in AWS Console:"
            print_info "https://console.aws.amazon.com/bedrock/"
        fi
    fi
    
    echo ""
    print_header "TEST COMPLETE"
    print_info "If you see a response above, Bedrock is working!"
    print_info "If you see errors, check model access in AWS Console."
}

main "$@" 