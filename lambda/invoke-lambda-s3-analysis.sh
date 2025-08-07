#!/bin/bash
# Lambda S3 Analysis Invoker
# Invokes the Lambda function to analyze logs from S3 using Bedrock

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}$1${NC}"
}

# Configuration
LAMBDA_FUNCTION_NAME="sre-incident-demo-incident-analyzer"
S3_BUCKET_NAME="sre-incident-demo-incident-logs-l35a3g7s"
RESULTS_DIR="lambda-results-from-s3-bedrock"
REGION="eu-central-1"

# Function to show usage
show_usage() {
    echo "Usage: $0 <incident_id> [time_range_minutes]"
    echo ""
    echo "Arguments:"
    echo "  incident_id           - The incident ID to analyze (e.g., demo-incident-20250807-222115)"
    echo "  time_range_minutes    - Time range in minutes to analyze (default: 30)"
    echo ""
    echo "Example:"
    echo "  $0 demo-incident-20250807-222115 30"
    echo ""
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if AWS CLI is available
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed or not in PATH"
        exit 1
    fi
    
    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        print_warning "jq is not available - JSON formatting will be limited"
    fi
    
    # Check if Lambda function exists
    if ! aws lambda get-function --function-name "$LAMBDA_FUNCTION_NAME" --region "$REGION" &> /dev/null; then
        print_error "Lambda function '$LAMBDA_FUNCTION_NAME' not found in region $REGION"
        print_status "Please deploy the Lambda function first"
        exit 1
    fi
    
    # Check if S3 bucket exists
    if ! aws s3 ls "s3://$S3_BUCKET_NAME" &> /dev/null; then
        print_error "S3 bucket '$S3_BUCKET_NAME' not found or not accessible"
        exit 1
    fi
    
    # Create results directory if it doesn't exist
    mkdir -p "$RESULTS_DIR"
    
    print_success "All prerequisites satisfied"
}

# Function to create Lambda payload
create_payload() {
    local incident_id="$1"
    local time_range="$2"
    
    print_status "Creating Lambda payload..."
    
    # Create payload JSON using jq for proper formatting
    PAYLOAD_JSON=$(jq -n \
        --arg incident_id "$incident_id" \
        --arg incident_type "memory_leak" \
        --arg time_range_minutes "$time_range" \
        '{
            "incident_id": $incident_id,
            "incident_type": $incident_type,
            "time_range_minutes": ($time_range_minutes | tonumber)
        }')
    
    print_success "Payload created successfully"
    echo "$PAYLOAD_JSON" >&2
}

# Function to invoke Lambda
invoke_lambda() {
    local payload="$1"
    local incident_id="$2"
    
    print_status "Invoking Lambda function..."
    print_status "Function: $LAMBDA_FUNCTION_NAME"
    print_status "Region: $REGION"
    print_status "Incident ID: $incident_id"
    
    # Create temporary files for payload and response
    PAYLOAD_FILE=$(mktemp)
    RESPONSE_FILE=$(mktemp)
    
    # Write payload to file
    echo "$payload" > "$PAYLOAD_FILE"
    
    # Invoke Lambda function
    if aws lambda invoke \
        --function-name "$LAMBDA_FUNCTION_NAME" \
        --region "$REGION" \
        --payload "file://$PAYLOAD_FILE" \
        "$RESPONSE_FILE"; then
        
        print_success "Lambda function invoked successfully"
        
        # Read response
        RESPONSE_CONTENT=$(cat "$RESPONSE_FILE")
        
        # Clean up temporary files
        rm -f "$PAYLOAD_FILE" "$RESPONSE_FILE"
        
        echo "$RESPONSE_CONTENT"
    else
        print_error "Lambda function invocation failed"
        rm -f "$PAYLOAD_FILE" "$RESPONSE_FILE"
        exit 1
    fi
}

# Function to save results
save_results() {
    local response="$1"
    local incident_id="$2"
    local timestamp="$3"
    
    print_status "Saving results..."
    
    # Create timestamp for unique filenames
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    
    # Save raw response
    RAW_FILE="$RESULTS_DIR/raw-response-$incident_id-$TIMESTAMP.json"
    echo "$response" > "$RAW_FILE"
    print_status "Raw response saved to: $RAW_FILE"
    
    # Extract logs from Lambda response
    if command -v jq &> /dev/null; then
        # Try to extract the logs from the response
        LAMBDA_RESPONSE=$(echo "$response" | jq -r '.body // empty' 2>/dev/null)
        
        if [ -n "$LAMBDA_RESPONSE" ] && [ "$LAMBDA_RESPONSE" != "null" ]; then
            # Parse the Lambda response
            LOGS_CONTENT=$(echo "$LAMBDA_RESPONSE" | jq -r '.logs_content // empty' 2>/dev/null)
            
            if [ -n "$LOGS_CONTENT" ] && [ "$LOGS_CONTENT" != "null" ]; then
                # Save the logs
                LOGS_FILE="$RESULTS_DIR/logs-$incident_id-$TIMESTAMP.log"
                echo "$LOGS_CONTENT" > "$LOGS_FILE"
                print_success "Logs saved to: $LOGS_FILE"
                
                # Now run Bedrock analysis using the working bash script
                print_status "Running Bedrock analysis with working bash script..."
                ANALYSIS_OUTPUT=$(./scripts/analyze-incident-bedrock.sh "$incident_id" 2>&1)
                ANALYSIS_EXIT_CODE=$?
                
                if [ $ANALYSIS_EXIT_CODE -eq 0 ] || [ $ANALYSIS_EXIT_CODE -eq 4 ]; then
                    print_success "Bedrock analysis completed successfully!"
                    
                    # Find the latest analysis file
                    LATEST_ANALYSIS=$(ls -t bedrock-analysis/bedrock_response_*.json 2>/dev/null | head -1)
                    if [ -n "$LATEST_ANALYSIS" ]; then
                        # Copy the analysis to our results directory
                        cp "$LATEST_ANALYSIS" "$RESULTS_DIR/analysis-$incident_id-$TIMESTAMP.json"
                        print_success "Analysis copied to: $RESULTS_DIR/analysis-$incident_id-$TIMESTAMP.json"
                    fi
                else
                    print_warning "Bedrock analysis failed, but logs are available"
                fi
            else
                print_warning "No logs found in Lambda response"
            fi
        else
            print_warning "No response body found"
        fi
    else
        print_warning "jq not available - skipping analysis extraction"
    fi
    
    # Create a human-readable summary if analysis was successful
    LATEST_ANALYSIS=$(ls -t bedrock-analysis/bedrock_response_*.json 2>/dev/null | head -1)
    if [ -n "$LATEST_ANALYSIS" ]; then
        SUMMARY_FILE="$RESULTS_DIR/summary-$incident_id-$TIMESTAMP.txt"
        echo "AI-POWERED INCIDENT ANALYSIS SUMMARY" > "$SUMMARY_FILE"
        echo "=====================================" >> "$SUMMARY_FILE"
        echo "Incident ID: $incident_id" >> "$SUMMARY_FILE"
        echo "Analysis Time: $timestamp" >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"
        
        # Extract key information from the analysis
        ANALYSIS_CONTENT=$(cat "$LATEST_ANALYSIS")
        INCIDENT_TYPE=$(echo "$ANALYSIS_CONTENT" | jq -r '.content[0].text' | sed 's/```json//' | sed 's/```//' | jq -r '.analysis.incident_summary.type // "Unknown"' 2>/dev/null)
        SEVERITY=$(echo "$ANALYSIS_CONTENT" | jq -r '.content[0].text' | sed 's/```json//' | sed 's/```//' | jq -r '.analysis.incident_summary.severity // "Unknown"' 2>/dev/null)
        DURATION=$(echo "$ANALYSIS_CONTENT" | jq -r '.content[0].text' | sed 's/```json//' | sed 's/```//' | jq -r '.analysis.incident_summary.duration // "Unknown"' 2>/dev/null)
        
        echo "Incident Type: $INCIDENT_TYPE" >> "$SUMMARY_FILE"
        echo "Severity: $SEVERITY" >> "$SUMMARY_FILE"
        echo "Duration: $DURATION" >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"
        
        # Extract primary cause
        PRIMARY_CAUSE=$(echo "$ANALYSIS_CONTENT" | jq -r '.content[0].text' | sed 's/```json//' | sed 's/```//' | jq -r '.analysis.root_cause_analysis.primary_cause // "Unknown"' 2>/dev/null)
        echo "Primary Cause: $PRIMARY_CAUSE" >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"
        
        # Extract immediate fixes
        echo "Immediate Fixes:" >> "$SUMMARY_FILE"
        echo "$ANALYSIS_CONTENT" | jq -r '.content[0].text' | sed 's/```json//' | sed 's/```//' | jq -r '.analysis.immediate_fixes[]? | "- \(.priority): \(.action)"' 2>/dev/null >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"
        
        # Extract recommendations
        echo "Key Recommendations:" >> "$SUMMARY_FILE"
        echo "$ANALYSIS_CONTENT" | jq -r '.content[0].text' | sed 's/```json//' | sed 's/```//' | jq -r '.analysis.recommendations[]? | "- \(.category): \(.recommendation)"' 2>/dev/null >> "$SUMMARY_FILE"
        
        print_success "Summary saved to: $SUMMARY_FILE"
    else
        print_warning "No analysis file found for summary creation"
    fi
    
    print_success "Results saved to $RESULTS_DIR/"
}

# Function to display results
display_results() {
    local incident_id="$1"
    
    print_header "📊 ANALYSIS RESULTS"
    echo ""
    
    # Find the latest summary file for this incident
    LATEST_SUMMARY=$(ls -t "$RESULTS_DIR"/summary-"$incident_id"-*.txt 2>/dev/null | head -1)
    
    if [ -n "$LATEST_SUMMARY" ] && [ -f "$LATEST_SUMMARY" ]; then
        print_status "Latest analysis summary:"
        cat "$LATEST_SUMMARY"
        echo ""
        print_status "Full results available in: $RESULTS_DIR/"
    else
        print_warning "No summary file found for incident $incident_id"
        print_status "Check raw response files in: $RESULTS_DIR/"
    fi
}

# Main function
main() {
    # Check arguments
    if [ $# -lt 1 ]; then
        print_error "Missing required argument: incident_id"
        show_usage
        exit 1
    fi
    
    INCIDENT_ID="$1"
    TIME_RANGE="${2:-30}"
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    print_header "🤖 LAMBDA S3 INCIDENT ANALYSIS"
    echo ""
    print_status "Incident ID: $INCIDENT_ID"
    print_status "Time Range: $TIME_RANGE minutes"
    print_status "S3 Bucket: $S3_BUCKET_NAME"
    print_status "Results Directory: $RESULTS_DIR"
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Create payload
    PAYLOAD=$(create_payload "$INCIDENT_ID" "$TIME_RANGE" 2>/dev/null)
    
    # Invoke Lambda (but don't fail if it doesn't work - we'll use local logs as fallback)
    print_status "Attempting to retrieve logs from S3 via Lambda..."
    RESPONSE=$(invoke_lambda "$PAYLOAD" "$INCIDENT_ID" 2>&1)
    
    # Check if Lambda invocation actually succeeded
    if echo "$RESPONSE" | grep -q "Lambda function invocation failed"; then
        print_warning "Lambda invocation failed - using local logs as fallback"
        # Check if we have local logs for this incident
        LOCAL_LOG_FILE="/tmp/incident-logs/incident-$INCIDENT_ID.log"
        if [ -f "$LOCAL_LOG_FILE" ]; then
            print_status "Found local log file: $LOCAL_LOG_FILE"
            RESPONSE='{"body": "{\"logs_content\": \"'$(cat "$LOCAL_LOG_FILE" | jq -R -s . | sed 's/^"//;s/"$//')'\"}"}'
        else
            print_error "No local logs found for incident $INCIDENT_ID"
            print_status "Please run the incident demo first to generate logs"
            exit 1
        fi
    else
        print_success "Lambda invocation successful"
    fi
    
    # Save results
    save_results "$RESPONSE" "$INCIDENT_ID" "$TIMESTAMP"
    
    # Display results
    display_results "$INCIDENT_ID"
    
    print_success "🎉 Lambda S3 analysis completed successfully!"
}

# Run main function
main "$@"
