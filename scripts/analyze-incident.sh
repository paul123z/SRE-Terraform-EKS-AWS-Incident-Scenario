#!/bin/bash

# AI-Powered Incident Analysis Script
# This script triggers the Lambda function to analyze incident logs using AWS Bedrock

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
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

print_ai() {
    echo -e "${PURPLE}[AI ANALYSIS]${NC} $1"
}

print_header() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}================================${NC}"
}

# Configuration
AWS_REGION="eu-central-1"
AWS_CMD=$(command -v aws || echo "/usr/local/bin/aws")

# Function to check AWS credentials
check_aws_credentials() {
    print_status "Checking AWS credentials..."
    
    if ! $AWS_CMD sts get-caller-identity > /dev/null 2>&1; then
        print_error "AWS credentials not configured"
        print_status "Please run: aws configure"
        exit 1
    fi
    
    print_success "AWS credentials verified"
}

# Function to get Lambda function name
get_lambda_function_name() {
    print_status "Getting Lambda function name from Terraform output..."
    
    # Try to get from Terraform output
    if command -v terraform &> /dev/null; then
        cd terraform
        LAMBDA_FUNCTION=$(terraform output -raw incident_analyzer_lambda 2>/dev/null || echo "")
        cd - > /dev/null
        
        if [ -n "$LAMBDA_FUNCTION" ]; then
            echo "$LAMBDA_FUNCTION"
            return
        fi
    fi
    
    # Fallback to default name
    echo "sre-incident-demo-incident-analyzer"
}

# Function to get S3 bucket name
get_s3_bucket_name() {
    print_status "Getting S3 bucket name from Terraform output..."
    
    # Try to get from Terraform output
    if command -v terraform &> /dev/null; then
        cd terraform
        S3_BUCKET=$(terraform output -raw incident_logs_bucket 2>/dev/null || echo "")
        cd - > /dev/null
        
        if [ -n "$S3_BUCKET" ]; then
            echo "$S3_BUCKET"
            return
        fi
    fi
    
    # Fallback to default name pattern
    echo "sre-incident-demo-incident-logs-$(date +%s)"
}

# Function to trigger Lambda analysis
trigger_lambda_analysis() {
    local incident_id="$1"
    local incident_type="$2"
    local time_range_minutes="$3"
    
    local lambda_function="$4"
    
    print_status "Triggering Lambda analysis..."
    print_status "Incident ID: $incident_id"
    print_status "Incident Type: $incident_type"
    print_status "Time Range: $time_range_minutes minutes"
    print_status "Lambda Function: $lambda_function"
    
    # Prepare payload
    local payload=$(cat << EOF
{
    "incident_id": "$incident_id",
    "incident_type": "$incident_type",
    "time_range_minutes": $time_range_minutes
}
EOF
)
    
    # Invoke Lambda function
    print_status "Invoking Lambda function..."
    
    local response
    response=$($AWS_CMD lambda invoke \
        --function-name "$lambda_function" \
        --payload "$payload" \
        --region "$AWS_REGION" \
        --cli-binary-format raw-in-base64-out \
        /tmp/lambda_response.json 2>&1)
    
    if [ $? -ne 0 ]; then
        print_error "Failed to invoke Lambda function: $response"
        return 1
    fi
    
    print_success "Lambda function invoked successfully"
    
    # Parse and display response
    if [ -f /tmp/lambda_response.json ]; then
        local status_code=$(jq -r '.StatusCode' /tmp/lambda_response.json 2>/dev/null || echo "unknown")
        
        if [ "$status_code" = "200" ]; then
            print_success "Analysis completed successfully"
            return 0
        else
            print_error "Lambda function failed with status code: $status_code"
            return 1
        fi
    else
        print_error "No response file found"
        return 1
    fi
}

# Function to display analysis results
display_analysis_results() {
    print_header "AI-POWERED INCIDENT ANALYSIS RESULTS"
    
    if [ ! -f /tmp/lambda_response.json ]; then
        print_error "No analysis results found"
        return 1
    fi
    
    # Extract the response body
    local response_body
    response_body=$(jq -r '.body' /tmp/lambda_response.json 2>/dev/null || echo "")
    
    if [ -z "$response_body" ]; then
        print_error "No response body found"
        return 1
    fi
    
    # Parse the JSON response
    local analysis
    analysis=$(echo "$response_body" | jq -r '.analysis' 2>/dev/null || echo "")
    
    if [ -z "$analysis" ]; then
        print_error "No analysis data found"
        echo "Raw response: $response_body"
        return 1
    fi
    
    # Check for errors
    local error
    error=$(echo "$analysis" | jq -r '.error // empty' 2>/dev/null || echo "")
    
    if [ -n "$error" ]; then
        print_error "Analysis error: $error"
        local raw_response
        raw_response=$(echo "$analysis" | jq -r '.raw_response // empty' 2>/dev/null || echo "")
        if [ -n "$raw_response" ]; then
            echo "Raw response: $raw_response"
        fi
        return 1
    fi
    
    # Display incident summary
    print_header "INCIDENT SUMMARY"
    local incident_summary
    incident_summary=$(echo "$analysis" | jq -r '.incident_summary // empty' 2>/dev/null || echo "")
    
    if [ -n "$incident_summary" ]; then
        echo "Type: $(echo "$incident_summary" | jq -r '.type // "Unknown"')"
        echo "Severity: $(echo "$incident_summary" | jq -r '.severity // "Unknown"')"
        echo "Duration: $(echo "$incident_summary" | jq -r '.duration // "Unknown"')"
        echo "Affected Services: $(echo "$incident_summary" | jq -r '.affected_services // []' | jq -r 'join(", ") // "None"')"
    fi
    
    # Display root cause analysis
    print_header "ROOT CAUSE ANALYSIS"
    local rca
    rca=$(echo "$analysis" | jq -r '.root_cause_analysis // empty' 2>/dev/null || echo "")
    
    if [ -n "$rca" ]; then
        echo "Primary Cause: $(echo "$rca" | jq -r '.primary_cause // "Unknown"')"
        echo ""
        echo "Contributing Factors:"
        echo "$rca" | jq -r '.contributing_factors // []' | jq -r '.[] // empty' | while read -r factor; do
            if [ -n "$factor" ]; then
                echo "  • $factor"
            fi
        done
    fi
    
    # Display immediate fixes
    print_header "IMMEDIATE FIXES"
    local immediate_fixes
    immediate_fixes=$(echo "$analysis" | jq -r '.immediate_fixes // []' 2>/dev/null || echo "")
    
    if [ -n "$immediate_fixes" ] && [ "$immediate_fixes" != "[]" ]; then
        echo "$immediate_fixes" | jq -r '.[] | "\(.priority | ascii_upcase): \(.action)"' | while read -r fix; do
            if [ -n "$fix" ]; then
                echo "  • $fix"
            fi
        done
    else
        echo "No immediate fixes identified"
    fi
    
    # Display preventive measures
    print_header "PREVENTIVE MEASURES"
    local preventive_measures
    preventive_measures=$(echo "$analysis" | jq -r '.preventive_measures // []' 2>/dev/null || echo "")
    
    if [ -n "$preventive_measures" ] && [ "$preventive_measures" != "[]" ]; then
        echo "$preventive_measures" | jq -r '.[] | "\(.measure) (Timeline: \(.timeline))"' | while read -r measure; do
            if [ -n "$measure" ]; then
                echo "  • $measure"
            fi
        done
    else
        echo "No preventive measures identified"
    fi
    
    # Display lessons learned
    print_header "LESSONS LEARNED"
    local lessons_learned
    lessons_learned=$(echo "$analysis" | jq -r '.lessons_learned // []' 2>/dev/null || echo "")
    
    if [ -n "$lessons_learned" ] && [ "$lessons_learned" != "[]" ]; then
        echo "$lessons_learned" | jq -r '.[] // empty' | while read -r lesson; do
            if [ -n "$lesson" ]; then
                echo "  • $lesson"
            fi
        done
    else
        echo "No lessons learned identified"
    fi
    
    # Display recommendations
    print_header "RECOMMENDATIONS"
    local recommendations
    recommendations=$(echo "$analysis" | jq -r '.recommendations // []' 2>/dev/null || echo "")
    
    if [ -n "$recommendations" ] && [ "$recommendations" != "[]" ]; then
        echo "$recommendations" | jq -r '.[] | "\(.category | ascii_upcase) (\(.impact | ascii_upcase)): \(.recommendation)"' | while read -r recommendation; do
            if [ -n "$recommendation" ]; then
                echo "  • $recommendation"
            fi
        done
    else
        echo "No recommendations identified"
    fi
    
    print_header "ANALYSIS COMPLETE"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -i, --incident-id ID       Incident ID (default: demo-incident)"
    echo "  -t, --type TYPE            Incident type (default: memory_leak)"
    echo "  -r, --time-range MINUTES   Time range in minutes (default: 30)"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Analyze default incident"
    echo "  $0 -i memory-leak-001 -t memory_leak  # Analyze specific incident"
    echo "  $0 -r 60                              # Analyze last 60 minutes"
}

# Main function
main() {
    # Default values
    local incident_id="demo-incident"
    local incident_type="memory_leak"
    local time_range_minutes=30
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--incident-id)
                incident_id="$2"
                shift 2
                ;;
            -t|--type)
                incident_type="$2"
                shift 2
                ;;
            -r|--time-range)
                time_range_minutes="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    print_header "AI-POWERED INCIDENT ANALYSIS"
    echo ""
    
    # Check AWS credentials
    check_aws_credentials
    
    # Get Lambda function name
    local lambda_function
    lambda_function=$(get_lambda_function_name)
    
    # Get S3 bucket name
    local s3_bucket
    s3_bucket=$(get_s3_bucket_name)
    
    print_status "Configuration:"
    echo "  Region: $AWS_REGION"
    echo "  Lambda Function: $lambda_function"
    echo "  S3 Bucket: $s3_bucket"
    echo ""
    
    # Trigger Lambda analysis
    if trigger_lambda_analysis "$incident_id" "$incident_type" "$time_range_minutes" "$lambda_function"; then
        echo ""
        display_analysis_results
    else
        print_error "Analysis failed"
        exit 1
    fi
}

# Run main function
main "$@" 