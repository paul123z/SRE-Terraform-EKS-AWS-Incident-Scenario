#!/bin/bash

# Simple AI Incident Analysis Script
# This script uses the working Lambda invocation method

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

# Check if incident ID is provided
if [ $# -eq 0 ]; then
    print_error "Usage: $0 <incident_id>"
    print_error "Example: $0 demo-incident-20250806-190142"
    exit 1
fi

INCIDENT_ID="$1"

print_header "================================
AI-POWERED INCIDENT ANALYSIS
================================"

print_status "Checking AWS credentials..."
if aws sts get-caller-identity &> /dev/null; then
    print_success "AWS credentials verified"
else
    print_error "AWS credentials not configured"
    exit 1
fi

print_status "Configuration:"
echo "  Region: $AWS_REGION"
echo "  Lambda Function: $LAMBDA_FUNCTION"
echo "  Incident ID: $INCIDENT_ID"

print_status "Triggering Lambda analysis..."

# Prepare payload
PAYLOAD_JSON="{\"incident_id\": \"$INCIDENT_ID\", \"incident_type\": \"memory_leak\", \"time_range_minutes\": 30}"
PAYLOAD_B64=$(echo "$PAYLOAD_JSON" | base64 -w 0)

print_status "Invoking Lambda function..."

# Invoke Lambda using the working method
if aws lambda invoke \
    --function-name "$LAMBDA_FUNCTION" \
    --payload "$PAYLOAD_B64" \
    --region "$AWS_REGION" \
    /tmp/lambda_response.json; then
    
    print_success "Lambda function invoked successfully"
    
    # Display results
    if [ -f /tmp/lambda_response.json ]; then
        print_header "AI-POWERED INCIDENT ANALYSIS RESULTS"
        echo ""
        
        # Extract and format the response
        if command -v jq &> /dev/null; then
            RESPONSE_BODY=$(cat /tmp/lambda_response.json | jq -r '.body' 2>/dev/null || echo "")
            
            if [ -n "$RESPONSE_BODY" ]; then
                # Parse the JSON string from the body field
                ANALYSIS_DATA=$(echo "$RESPONSE_BODY" | jq '.' 2>/dev/null)
            
            if [ $? -eq 0 ]; then
                # Display the analysis in a structured, readable format
                echo ""
                print_header "📊 INCIDENT SUMMARY"
                echo "$ANALYSIS_DATA" | jq -r '.analysis.incident_summary | "Type: \(.type) | Severity: \(.severity) | Duration: \(.duration)"'
                echo "$ANALYSIS_DATA" | jq -r '.analysis.incident_summary.affected_services[] | "Affected: \(.)"'
                
                echo ""
                print_header "🔍 ROOT CAUSE ANALYSIS"
                echo "$ANALYSIS_DATA" | jq -r '.analysis.root_cause_analysis.primary_cause | "Primary Cause: \(.)"'
                echo "$ANALYSIS_DATA" | jq -r '.analysis.root_cause_analysis.contributing_factors[] | "• \(.)"'
                
                echo ""
                print_header "⚡ IMMEDIATE FIXES"
                echo "$ANALYSIS_DATA" | jq -r '.analysis.immediate_fixes[] | "\(.priority | ascii_upcase): \(.action) - \(.description)"'
                
                echo ""
                print_header "🛡️ PREVENTIVE MEASURES"
                echo "$ANALYSIS_DATA" | jq -r '.analysis.preventive_measures[] | "\(.measure): \(.implementation) (Timeline: \(.timeline))"'
                
                echo ""
                print_header "📚 LESSONS LEARNED"
                echo "$ANALYSIS_DATA" | jq -r '.analysis.lessons_learned[] | "• \(.)"'
                
                echo ""
                print_header "💡 RECOMMENDATIONS"
                echo "$ANALYSIS_DATA" | jq -r '.analysis.recommendations[] | "\(.category | ascii_upcase): \(.recommendation) (Impact: \(.impact))"'
                
                echo ""
                print_header "🤖 AI ANALYSIS STATUS"
                ANALYSIS_TYPE=$(echo "$ANALYSIS_DATA" | jq -r '.analysis.analysis_type')
                if [ "$ANALYSIS_TYPE" = "fallback" ]; then
                    print_warning "Using intelligent fallback analysis (Bedrock access not enabled)"
                    print_status "This provides professional SRE analysis with structured recommendations"
                else
                    print_success "Full AI analysis completed using AWS Bedrock"
                fi
            else
                # Fallback to raw display if jq parsing fails
                echo "$RESPONSE_BODY"
            fi
        else
            print_error "No response body found"
            cat /tmp/lambda_response.json
        fi
    else
        # Fallback when jq is not available
        print_warning "jq not available, showing raw response"
        cat /tmp/lambda_response.json
    fi
    else
        print_error "No response file found"
    fi
else
    print_error "Failed to invoke Lambda function"
    exit 1
fi

print_success "Analysis completed!" 