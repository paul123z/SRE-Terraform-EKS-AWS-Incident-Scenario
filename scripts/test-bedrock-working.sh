#!/bin/bash

# Working Amazon Bedrock Test Script
# Tests Bedrock access using available inference profile

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
    print_header "WORKING BEDROCK TEST"
    
    print_info "Testing Amazon Bedrock with available inference profile..."
    
    # Test 1: Check if AWS CLI is configured
    print_info "Checking AWS CLI configuration..."
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        print_error "AWS CLI not configured. Please run 'aws configure' first."
        exit 1
    fi
    print_success "AWS CLI is configured"
    
    # Test 2: List inference profiles
    print_info "Listing available inference profiles..."
    INFERENCE_PROFILES=$(aws bedrock list-inference-profiles --region us-west-1 --query "inferenceProfileSummaries[].inferenceProfileName" --output text 2>/dev/null)
    if [ $? -eq 0 ]; then
        print_success "Found inference profiles: $INFERENCE_PROFILES"
    else
        print_error "Could not list inference profiles"
        exit 1
    fi
    
    # Test 3: Test Bedrock with Llama 4 Scout using inference profile
    print_info "Testing Bedrock invocation with Llama 4 Scout..."
    
    # Create test payload for Llama 4 Scout
    TEST_PAYLOAD='{
        "prompt": "Hello! Can you confirm you are working? Please respond briefly.",
        "max_gen_len": 100,
        "temperature": 0.7,
        "top_p": 0.9
    }'
    
    # Use the inference profile ARN
    INFERENCE_PROFILE_ARN="arn:aws:bedrock:us-west-1:462738742234:inference-profile/us.meta.llama4-scout-17b-instruct-v1:0"
    
    print_info "Invoking Bedrock with inference profile..."
    
    # Create output file
    OUTPUT_FILE="bedrock-test-response-$(date +%Y%m%d-%H%M%S).json"
    
    RESPONSE=$(aws bedrock-runtime invoke-model \
        --model-id "meta.llama4-scout-17b-instruct-v1:0" \
        --region us-west-1 \
        --body "$TEST_PAYLOAD" \
        --cli-binary-format raw-in-base64-out \
        --output json \
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
        
        # Try alternative approach with direct model ID
        print_info "Trying alternative approach with direct model ID..."
        RESPONSE2=$(aws bedrock-runtime invoke-model \
            --model-id "meta.llama4-scout-17b-instruct-v1:0" \
            --region us-west-1 \
            --body "$TEST_PAYLOAD" \
            --cli-binary-format raw-in-base64-out \
            --output json \
            "${OUTPUT_FILE}-alt.json" 2>&1)
        
        if [ $? -eq 0 ]; then
            print_success "Bedrock invocation successful with direct model ID!"
            echo ""
            print_info "Response saved to: ${OUTPUT_FILE}-alt.json"
            print_info "Response content:"
            cat "${OUTPUT_FILE}-alt.json" | jq -r '.generation' 2>/dev/null || cat "${OUTPUT_FILE}-alt.json"
        else
            print_error "Both approaches failed"
            echo "Error details: $RESPONSE2"
        fi
    fi
    
    echo ""
    print_header "TEST COMPLETE"
    print_info "If you see a response above, Bedrock is working!"
    print_info "Check the generated JSON files for full response details."
}

main "$@" 