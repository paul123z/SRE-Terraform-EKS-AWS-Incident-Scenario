#!/bin/bash

# Debug Lambda Function Script
# This script helps debug what's happening in the Lambda function

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
LAMBDA FUNCTION DEBUG
================================"

print_status "Testing Lambda function with detailed error checking..."

# Prepare a simple test payload
TEST_PAYLOAD='{"incident_id": "debug-test-123", "incident_type": "memory_leak", "time_range_minutes": 30}'
PAYLOAD_B64=$(echo "$TEST_PAYLOAD" | base64 -w 0)

print_status "Invoking Lambda function..."

# Invoke Lambda and capture the full response
RESPONSE_FILE="/tmp/lambda_debug_response.json"
ERROR_FILE="/tmp/lambda_debug_error.json"

/usr/local/aws-cli/v2/current/bin/aws lambda invoke \
    --function-name sre-incident-demo-incident-analyzer \
    --payload "$PAYLOAD_B64" \
    --region eu-central-1 \
    "$RESPONSE_FILE" \
    --log-type Tail \
    --query 'LogResult' \
    --output text | base64 -d > "$ERROR_FILE" 2>/dev/null || true

# Check the response
if [ -f "$RESPONSE_FILE" ]; then
    print_status "Lambda Response:"
    cat "$RESPONSE_FILE"
    echo ""
    
    # Check if there's an error
    if grep -q "FunctionError" "$RESPONSE_FILE"; then
        print_error "Lambda function has an error"
        
        # Check the error logs
        if [ -f "$ERROR_FILE" ]; then
            print_status "Lambda Error Logs:"
            cat "$ERROR_FILE"
            echo ""
        fi
        
        # Try to get recent CloudWatch logs
        print_status "Getting recent CloudWatch logs..."
        /usr/local/aws-cli/v2/current/bin/aws logs describe-log-streams \
            --log-group-name "/aws/lambda/sre-incident-demo-incident-analyzer" \
            --region eu-central-1 \
            --order-by LastEventTime \
            --descending \
            --max-items 1 \
            --query 'logStreams[0].logStreamName' \
            --output text > /tmp/latest_log_stream.txt 2>/dev/null || echo "No log streams found"
        
        if [ -f /tmp/latest_log_stream.txt ]; then
            LATEST_STREAM=$(cat /tmp/latest_log_stream.txt)
            if [ "$LATEST_STREAM" != "No log streams found" ] && [ "$LATEST_STREAM" != "None" ]; then
                print_status "Latest log stream: $LATEST_STREAM"
                print_status "Recent logs:"
                /usr/local/aws-cli/v2/current/bin/aws logs get-log-events \
                    --log-group-name "/aws/lambda/sre-incident-demo-incident-analyzer" \
                    --log-stream-name "$LATEST_STREAM" \
                    --region eu-central-1 \
                    --start-time $(($(date +%s) - 300))000 \
                    --query 'events[*].message' \
                    --output text | tail -10
            fi
        fi
    else
        print_success "Lambda function executed successfully"
        
        # Parse the response
        RESPONSE_BODY=$(cat "$RESPONSE_FILE" | jq -r '.body' 2>/dev/null || echo "")
        if [ -n "$RESPONSE_BODY" ]; then
            ANALYSIS_TYPE=$(echo "$RESPONSE_BODY" | jq -r '.analysis.analysis_type' 2>/dev/null || echo "unknown")
            print_status "Analysis Type: $ANALYSIS_TYPE"
            
            if [ "$ANALYSIS_TYPE" = "bedrock" ]; then
                print_success "🎉 BEDROCK IS WORKING!"
            else
                print_warning "Still using fallback analysis"
            fi
        fi
    fi
else
    print_error "No response file found"
fi

# Clean up
rm -f "$RESPONSE_FILE" "$ERROR_FILE" /tmp/latest_log_stream.txt

print_header "================================
DEBUG COMPLETE
================================" 