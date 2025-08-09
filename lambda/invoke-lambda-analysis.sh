#!/bin/bash

# Lambda Incident Analysis Invoker
# Invokes the Lambda function and stores results locally

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

# Configuration
LAMBDA_FUNCTION="sre-incident-demo-incident-analyzer"
LAMBDA_REGION="eu-central-1"
RESULTS_DIR="lambda-results-from-s3-bedrock"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Check if incident ID is provided
if [ $# -eq 0 ]; then
    print_error "Usage: $0 <incident_id> [time_range_minutes]"
    print_error "Example: $0 demo-incident-20250806-205443 30"
    exit 1
fi

INCIDENT_ID="$1"
TIME_RANGE="${2:-30}"

print_header "LAMBDA INCIDENT ANALYSIS INVOKER"

print_info "Configuration:"
echo "  Lambda Function: $LAMBDA_FUNCTION"
echo "  Lambda Region: $LAMBDA_REGION"
echo "  Incident ID: $INCIDENT_ID"
echo "  Time Range: $TIME_RANGE minutes"
echo "  Results Directory: $RESULTS_DIR"

# Create results directory
mkdir -p "$RESULTS_DIR"

# Create payload file
PAYLOAD_FILE="$RESULTS_DIR/payload-$INCIDENT_ID-$TIMESTAMP.json"
RESPONSE_FILE="$RESULTS_DIR/response-$INCIDENT_ID-$TIMESTAMP.json"
PROMPT_FILE="$RESULTS_DIR/prompt-$INCIDENT_ID-$TIMESTAMP.txt"

print_info "Creating payload..."
jq -n \
    --arg incident_id "$INCIDENT_ID" \
    --arg incident_type "memory_leak" \
    --argjson time_range_minutes "$TIME_RANGE" \
    '{
        incident_id: $incident_id,
        incident_type: $incident_type,
        time_range_minutes: $time_range_minutes
    }' > "$PAYLOAD_FILE"

print_success "Payload created: $PAYLOAD_FILE"

# Invoke Lambda function
print_info "Invoking Lambda function..."
print_info "This will retrieve logs from S3 in Frankfurt and call Bedrock in N. Carolina..."

# Check if AWS CLI is working
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed or not in PATH"
    print_info "Please install AWS CLI or check your PATH"
    exit 1
fi

print_info "AWS CLI found, attempting Lambda invocation..."

# Add timeout to prevent hanging
RESULT=$(timeout 60 aws lambda invoke \
    --function-name "$LAMBDA_FUNCTION" \
    --region "$LAMBDA_REGION" \
    --payload "file://$PAYLOAD_FILE" \
    --output json \
    "$RESPONSE_FILE" 2>&1)

if [ $? -eq 0 ]; then
    print_success "Lambda invocation successful!"
elif [ $? -eq 124 ]; then
    print_error "Lambda invocation timed out after 60 seconds"
    print_info "The Lambda function might be taking too long to process"
    print_info "Check CloudWatch logs for more details"
    exit 1
    
    # Parse and display results
    print_info "Response saved to: $RESPONSE_FILE"
    
    # Extract and format the response
    RESPONSE_CONTENT=$(cat "$RESPONSE_FILE")
    
    # Check if response contains analysis
    if echo "$RESPONSE_CONTENT" | jq -e '.body' > /dev/null 2>&1; then
        BODY_CONTENT=$(echo "$RESPONSE_CONTENT" | jq -r '.body')
        
        # Try to parse the body as JSON
        if echo "$BODY_CONTENT" | jq -e '.' > /dev/null 2>&1; then
            ANALYSIS=$(echo "$BODY_CONTENT" | jq -r '.')
            
            # Save the analysis separately
            ANALYSIS_FILE="$RESULTS_DIR/analysis-$INCIDENT_ID-$TIMESTAMP.json"
            echo "$ANALYSIS" | jq '.' > "$ANALYSIS_FILE"
            
            print_success "Analysis saved to: $ANALYSIS_FILE"
            
            # Display key information
            print_info "Analysis Summary:"
            if echo "$ANALYSIS" | jq -e '.incident_summary' > /dev/null 2>&1; then
                echo "  Type: $(echo "$ANALYSIS" | jq -r '.incident_summary.type // "Unknown"')"
                echo "  Severity: $(echo "$ANALYSIS" | jq -r '.incident_summary.severity // "Unknown"')"
                echo "  Duration: $(echo "$ANALYSIS" | jq -r '.incident_summary.duration // "Unknown"')"
            fi
            
            if echo "$ANALYSIS" | jq -e '.bedrock_status' > /dev/null 2>&1; then
                echo "  Bedrock Status: $(echo "$ANALYSIS" | jq -r '.bedrock_status // "Unknown"')"
            fi
            
            if echo "$ANALYSIS" | jq -e '.analysis_type' > /dev/null 2>&1; then
                echo "  Analysis Type: $(echo "$ANALYSIS" | jq -r '.analysis_type // "Unknown"')"
            fi
            
        else
            print_warning "Response body is not valid JSON"
            echo "$BODY_CONTENT" > "$PROMPT_FILE"
            print_info "Raw response saved to: $PROMPT_FILE"
        fi
    else
        print_warning "No body found in response"
        echo "$RESPONSE_CONTENT" > "$PROMPT_FILE"
        print_info "Full response saved to: $PROMPT_FILE"
    fi
    
else
    print_error "Lambda invocation failed"
    echo "Error: $RESULT"
    exit 1
fi

print_header "ANALYSIS COMPLETE"
print_info "Files created:"
echo "  Payload: $PAYLOAD_FILE"
echo "  Response: $RESPONSE_FILE"
if [ -f "$ANALYSIS_FILE" ]; then
    echo "  Analysis: $ANALYSIS_FILE"
fi
if [ -f "$PROMPT_FILE" ]; then
    echo "  Raw Response: $PROMPT_FILE"
fi

print_success "Cross-region analysis completed successfully!"
print_info "Lambda retrieved logs from S3 (Frankfurt) and called Bedrock (N. Carolina)"
