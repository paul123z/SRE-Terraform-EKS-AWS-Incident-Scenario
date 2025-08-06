#!/bin/bash

# Amazon Bedrock Test Script using Nova Lite
# Tests Bedrock access with Amazon's Nova Lite model

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
    print_header "NOVA LITE BEDROCK TEST"
    
    print_info "Testing Amazon Bedrock with Nova Lite model..."
    
    # Test 1: Check if AWS CLI is configured
    print_info "Checking AWS CLI configuration..."
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        print_error "AWS CLI not configured. Please run 'aws configure' first."
        exit 1
    fi
    print_success "AWS CLI is configured"
    
    # Test 2: Check Nova Lite model status
    print_info "Checking Nova Lite model status..."
    MODEL_STATUS=$(aws bedrock get-foundation-model --model-identifier "amazon.nova-lite-2024-05-20-v1:0" --region us-east-1 --query 'modelDetails.modelLifecycle.status' --output text 2>/dev/null)
    
    if [ "$MODEL_STATUS" = "ACTIVE" ]; then
        print_success "Nova Lite model is ACTIVE - ready for invocation"
    else
        print_warning "Model status is: $MODEL_STATUS"
        print_warning "You need to enable model access in AWS Console"
        print_info "Go to: https://console.aws.amazon.com/bedrock/"
        print_info "Click 'Model access' and request access for Nova Lite"
        exit 1
    fi
    
    # Test 3: Test Bedrock invocation with Nova Lite
    print_info "Testing Bedrock invocation with Nova Lite..."
    
    # Create output file with timestamp
    OUTPUT_FILE="nova-test-$(date +%Y%m%d-%H%M%S).json"
    
    # Use Nova Lite model with correct syntax
    RESPONSE=$(aws bedrock-runtime invoke-model \
        --region us-east-1 \
        --model-id "amazon.nova-lite-2024-05-20-v1:0" \
        --content-type "application/json" \
        --body '{
            "prompt": "Hello! Can you confirm that Bedrock is working? Please respond briefly.",
            "max_tokens": 100,
            "temperature": 0.7,
            "top_p": 0.9
        }' \
        --cli-binary-format raw-in-base64-out \
        "$OUTPUT_FILE" 2>&1)
    
    if [ $? -eq 0 ]; then
        print_success "Bedrock invocation successful!"
        echo ""
        print_info "Response saved to: $OUTPUT_FILE"
        print_info "Response content:"
        cat "$OUTPUT_FILE" | jq -r '.generation' 2>/dev/null || cat "$OUTPUT_FILE"
    else
        print_error "Bedrock invocation failed"
        echo "Error details: $RESPONSE"
        
        # Try alternative Nova Lite model ID
        print_info "Trying alternative Nova Lite model ID..."
        RESPONSE2=$(aws bedrock-runtime invoke-model \
            --region us-east-1 \
            --model-id "amazon.nova-lite-v1:0" \
            --content-type "application/json" \
            --body '{
                "prompt": "Hello! Can you confirm that Bedrock is working? Please respond briefly.",
                "max_tokens": 100,
                "temperature": 0.7,
                "top_p": 0.9
            }' \
            --cli-binary-format raw-in-base64-out \
            "${OUTPUT_FILE}-alt.json" 2>&1)
        
        if [ $? -eq 0 ]; then
            print_success "Bedrock invocation successful with alternative model ID!"
            echo ""
            print_info "Response saved to: ${OUTPUT_FILE}-alt.json"
            print_info "Response content:"
            cat "${OUTPUT_FILE}-alt.json" | jq -r '.generation' 2>/dev/null || cat "${OUTPUT_FILE}-alt.json"
        else
            print_error "Both Nova Lite model IDs failed"
            echo "Error details: $RESPONSE2"
        fi
    fi
    
    echo ""
    print_header "TEST COMPLETE"
    print_info "If you see a response above, Bedrock is working!"
    print_info "Check the generated JSON files for full response details."
}

main "$@" 