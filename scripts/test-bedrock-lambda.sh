#!/bin/bash

# Test Bedrock Access through Lambda
# This script tests if Bedrock is working by checking the Lambda response

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
AWS_REGION="eu-central-1"
LAMBDA_FUNCTION="sre-incident-demo-incident-analyzer"
TEST_INCIDENT_ID="bedrock-test-$(date +%Y%m%d-%H%M%S)"

print_header "================================
BEDROCK ACCESS TEST VIA LAMBDA
================================"

print_status "Testing Bedrock access through our Lambda function..."
print_status "This will show if Bedrock is enabled or still using fallback"

# Prepare payload
PAYLOAD_JSON="{\"incident_id\": \"$TEST_INCIDENT_ID\", \"incident_type\": \"memory_leak\", \"time_range_minutes\": 30}"
PAYLOAD_B64=$(echo "$PAYLOAD_JSON" | base64 -w 0)

print_status "Invoking Lambda function..."

# Invoke Lambda
if /usr/local/aws-cli/v2/current/bin/aws lambda invoke \
    --function-name "$LAMBDA_FUNCTION" \
    --payload "$PAYLOAD_B64" \
    --region "$AWS_REGION" \
    /tmp/bedrock_test_response.json; then
    
    print_success "Lambda function invoked successfully"
    
    # Check the response
    if [ -f /tmp/bedrock_test_response.json ]; then
        RESPONSE_BODY=$(cat /tmp/bedrock_test_response.json | jq -r '.body' 2>/dev/null || echo "")
        
        if [ -n "$RESPONSE_BODY" ]; then
            ANALYSIS_TYPE=$(echo "$RESPONSE_BODY" | jq -r '.analysis.analysis_type' 2>/dev/null || echo "unknown")
            BEDROCK_STATUS=$(echo "$RESPONSE_BODY" | jq -r '.analysis.bedrock_status' 2>/dev/null || echo "unknown")
            
            echo ""
            print_header "🤖 BEDROCK ACCESS STATUS"
            echo "Analysis Type: $ANALYSIS_TYPE"
            echo "Bedrock Status: $BEDROCK_STATUS"
            echo ""
            
            if [ "$ANALYSIS_TYPE" = "bedrock" ]; then
                print_success "🎉 BEDROCK IS WORKING! Real AI analysis is being used!"
                print_status "You can now run the incident demo with full AI analysis"
            else
                print_warning "❌ Still using fallback analysis"
                print_status "You need to enable Bedrock model access in AWS console"
                print_status "Go to: https://console.aws.amazon.com/bedrock/"
                print_status "Click 'Request model access' for Anthropic's Claude"
            fi
        else
            print_error "No response body found"
        fi
    else
        print_error "No response file found"
    fi
else
    print_error "Failed to invoke Lambda function"
    exit 1
fi

# Clean up
rm -f /tmp/bedrock_test_response.json

print_header "================================
NEXT STEPS
================================"
if [ "$ANALYSIS_TYPE" = "bedrock" ]; then
    print_success "Run the incident demo with real AI:"
    print_status "./scripts/incident-demo.sh"
else
    print_warning "Enable Bedrock access first, then test again:"
    print_status "./scripts/test-bedrock-lambda.sh"
fi 