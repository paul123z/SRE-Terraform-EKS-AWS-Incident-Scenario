#!/bin/bash

# AI Incident Analysis Script using AWS Bedrock (Claude Sonnet 4)
# This script uses the working Bedrock call to analyze incident logs

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
AWS_REGION="us-west-1"
LOG_DIR="/tmp/incident-logs"
BEDROCK_MODEL="us.anthropic.claude-sonnet-4-20250514-v1:0"
ANALYSIS_DIR="$(pwd)/bedrock-analysis"

# Check if incident ID is provided
if [ $# -eq 0 ]; then
    print_error "Usage: $0 <incident_id>"
    print_error "Example: $0 demo-incident-20250806-205443"
    print_status "Available incident IDs:"
    if [ -d "$LOG_DIR" ]; then
        for log_file in "$LOG_DIR"/incident-*.log; do
            if [ -f "$log_file" ]; then
                incident_id=$(basename "$log_file" .log)
                echo "  $incident_id"
            fi
        done
    fi
    exit 1
fi

INCIDENT_ID="$1"
# Handle both patterns: incident-{id}.log and {id}.log
if [ -f "$LOG_DIR/incident-$INCIDENT_ID.log" ]; then
    INCIDENT_LOG_FILE="$LOG_DIR/incident-$INCIDENT_ID.log"
elif [ -f "$LOG_DIR/$INCIDENT_ID.log" ]; then
    INCIDENT_LOG_FILE="$LOG_DIR/$INCIDENT_ID.log"
else
    INCIDENT_LOG_FILE="$LOG_DIR/incident-$INCIDENT_ID.log"
fi

print_header "================================
AI-POWERED INCIDENT ANALYSIS WITH BEDROCK
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
echo "  Bedrock Model: $BEDROCK_MODEL"
echo "  Incident ID: $INCIDENT_ID"
echo "  Log File: $INCIDENT_LOG_FILE"
echo "  Analysis Directory: $ANALYSIS_DIR"

# Create analysis directory
mkdir -p "$ANALYSIS_DIR"

# Check if log file exists
if [ ! -f "$INCIDENT_LOG_FILE" ]; then
    print_error "Incident log file not found: $INCIDENT_LOG_FILE"
    print_status "Available log files:"
    if [ -d "$LOG_DIR" ]; then
        ls -la "$LOG_DIR"/incident-*.log 2>/dev/null || echo "No log files found"
    fi
    exit 1
fi

print_success "Found incident log file: $INCIDENT_LOG_FILE"

# Read the incident log file
print_status "Reading incident log file..."
INCIDENT_DATA=$(cat "$INCIDENT_LOG_FILE")

if [ -z "$INCIDENT_DATA" ]; then
    print_error "Incident log file is empty"
    exit 1
fi

print_success "Incident log loaded (${#INCIDENT_DATA} characters)"

# Create the analysis prompt
print_status "Preparing AI analysis prompt..."

# Create a temporary file for the prompt to avoid JSON escaping issues
TEMP_PROMPT_FILE="$ANALYSIS_DIR/bedrock_prompt_$$.txt"
cat > "$TEMP_PROMPT_FILE" << 'EOF'
You are an expert SRE (Site Reliability Engineer) analyzing a Kubernetes incident. Please analyze the following incident log data and provide a comprehensive incident analysis report.

Please provide your analysis in the following JSON format:

{
  "analysis": {
    "incident_summary": {
      "type": "string describing the incident type",
      "severity": "LOW|MEDIUM|HIGH|CRITICAL",
      "duration": "estimated duration of the incident",
      "affected_services": ["list of affected services"]
    },
    "root_cause_analysis": {
      "primary_cause": "string describing the primary root cause",
      "contributing_factors": ["list of contributing factors"]
    },
    "immediate_fixes": [
      {
        "priority": "HIGH|MEDIUM|LOW",
        "action": "string describing the action taken",
        "description": "string describing why this was done"
      }
    ],
    "preventive_measures": [
      {
        "measure": "string describing the preventive measure",
        "implementation": "string describing how to implement it",
        "timeline": "IMMEDIATE|SHORT_TERM|LONG_TERM"
      }
    ],
    "lessons_learned": ["list of lessons learned from this incident"],
    "recommendations": [
      {
        "category": "MONITORING|ALERTING|PROCESS|INFRASTRUCTURE",
        "recommendation": "string describing the recommendation",
        "impact": "HIGH|MEDIUM|LOW"
      }
    ],
    "analysis_type": "bedrock_analysis"
  }
}

Focus on:
1. Identifying the root cause from the logs
2. Understanding the incident timeline
3. Analyzing the resolution actions taken
4. Providing actionable recommendations
5. Suggesting preventive measures

Be specific and actionable in your recommendations.

INCIDENT LOG DATA:
EOF

# Append the incident data to the prompt file
echo "$INCIDENT_DATA" >> "$TEMP_PROMPT_FILE"

# Read the complete prompt
ANALYSIS_PROMPT=$(cat "$TEMP_PROMPT_FILE")

# Create the Bedrock request payload file
BEDROCK_PAYLOAD_FILE="$ANALYSIS_DIR/bedrock_payload_$$.json"
cat > "$BEDROCK_PAYLOAD_FILE" << EOF
{
  "anthropic_version": "bedrock-2023-05-31",
  "messages": [
    {
      "role": "user",
      "content": $(echo "$ANALYSIS_PROMPT" | jq -Rs .)
    }
  ],
  "temperature": 0.3,
  "max_tokens": 2000
}
EOF

print_status "Invoking AWS Bedrock for AI analysis..."

# Call Bedrock using the working method
if aws bedrock-runtime invoke-model \
  --region "$AWS_REGION" \
  --cli-binary-format raw-in-base64-out \
  --model-id "$BEDROCK_MODEL" \
  --content-type application/json \
  --accept application/json \
  --body "file://$BEDROCK_PAYLOAD_FILE" \
  "$ANALYSIS_DIR/bedrock_response_$$.json"; then
    
    print_success "Bedrock analysis completed successfully"
    
    # Display results
    if [ -f "$ANALYSIS_DIR/bedrock_response_$$.json" ]; then
        print_header "AI-POWERED INCIDENT ANALYSIS RESULTS"
        echo ""
        
        # Extract and format the response
        if command -v jq &> /dev/null; then
            RESPONSE_CONTENT=$(cat "$ANALYSIS_DIR/bedrock_response_$$.json" | jq -r '.content[0].text' 2>/dev/null || echo "")
            
            if [ -n "$RESPONSE_CONTENT" ]; then
                # Try to parse the JSON response
                ANALYSIS_DATA=$(echo "$RESPONSE_CONTENT" | jq '.' 2>/dev/null)
                
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
                    print_success "Full AI analysis completed using AWS Bedrock (Claude Sonnet 4)"
                    
                    # Save the structured analysis to a file
                    ANALYSIS_FILE="$ANALYSIS_DIR/incident-analysis-$INCIDENT_ID.json"
                    echo "$ANALYSIS_DATA" > "$ANALYSIS_FILE"
                    print_status "Structured analysis saved to: $ANALYSIS_FILE"
                    
                else
                    # Fallback to raw display if JSON parsing fails
                    print_warning "Could not parse JSON response, showing raw analysis:"
                    echo "$RESPONSE_CONTENT"
                fi
            else
                print_error "No response content found"
                cat "$ANALYSIS_DIR/bedrock_response_$$.json"
            fi
        else
            # Fallback when jq is not available
            print_warning "jq not available, showing raw response"
            cat "$ANALYSIS_DIR/bedrock_response_$$.json"
        fi
    else
        print_error "No response file found"
    fi
else
    print_error "Failed to invoke Bedrock"
    exit 1
fi

# Clean up temporary files
rm -f "$TEMP_PROMPT_FILE" "$BEDROCK_PAYLOAD_FILE"

print_success "AI-powered incident analysis completed!"
print_status "This analysis was performed using AWS Bedrock (Claude Sonnet 4) on the incident logs"
print_status "The analysis works even after infrastructure is torn down since it only requires the log files"
print_status "Analysis files saved in: $ANALYSIS_DIR" 