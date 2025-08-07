#!/bin/bash

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
AWS_REGION="us-west-1"
BEDROCK_MODEL="us.anthropic.claude-sonnet-4-20250514-v1:0"
LOG_FILE="./incident-log.log"

print_header "🤖 AI-POWERED INCIDENT ANALYSIS"
echo ""
print_status "Analyzing log file: $LOG_FILE"
print_status "Bedrock model: $BEDROCK_MODEL"
print_status "AWS region: $AWS_REGION"
echo ""

# Check if log file exists
if [ ! -f "$LOG_FILE" ]; then
    print_error "Log file not found: $LOG_FILE"
    exit 1
fi

# Read log content
LOGS_CONTENT=$(cat "$LOG_FILE")
LOG_SIZE=$(echo "$LOGS_CONTENT" | wc -c)

print_status "Log content loaded (size: $LOG_SIZE characters)"

# Create analysis prompt using temporary file to avoid JSON escaping issues
TEMP_PROMPT_FILE="./bedrock_prompt_$$.txt"
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

# Append the log content to the prompt file
echo "$LOGS_CONTENT" >> "$TEMP_PROMPT_FILE"

# Read the complete prompt
ANALYSIS_PROMPT=$(cat "$TEMP_PROMPT_FILE")

# Create the Bedrock request payload file
BEDROCK_PAYLOAD_FILE="./bedrock_payload_$$.json"
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

print_status "Invoking AWS Bedrock for analysis..."

# Call Bedrock using the working method
if aws bedrock-runtime invoke-model \
  --region "$AWS_REGION" \
  --cli-binary-format raw-in-base64-out \
  --model-id "$BEDROCK_MODEL" \
  --content-type application/json \
  --accept application/json \
  --body "file://$BEDROCK_PAYLOAD_FILE" \
  bedrock-response.json; then
    
    print_success "Bedrock analysis completed successfully!"
    
    # Parse and display results
    RESPONSE_CONTENT=$(cat bedrock-response.json)
    
    if command -v jq &> /dev/null; then
        # Extract the analysis text
        ANALYSIS_TEXT=$(echo "$RESPONSE_CONTENT" | jq -r '.content[0].text // empty')
        
        if [ -n "$ANALYSIS_TEXT" ]; then
            print_header "📊 INCIDENT ANALYSIS RESULTS"
            echo ""
            
            # Try to extract JSON from the response
            JSON_START=$(echo "$ANALYSIS_TEXT" | grep -o '{.*}' | head -1)
            
            if [ -n "$JSON_START" ]; then
                # Parse and display structured results
                echo "$JSON_START" | jq -r '.analysis.incident_summary | "INCIDENT SUMMARY:"'
                echo "$JSON_START" | jq -r '.analysis.incident_summary | "  Type: \(.type)"'
                echo "$JSON_START" | jq -r '.analysis.incident_summary | "  Severity: \(.severity)"'
                echo "$JSON_START" | jq -r '.analysis.incident_summary | "  Duration: \(.duration)"'
                echo ""
                
                echo "$JSON_START" | jq -r '.analysis.root_cause_analysis | "ROOT CAUSE ANALYSIS:"'
                echo "$JSON_START" | jq -r '.analysis.root_cause_analysis | "  Primary Cause: \(.primary_cause)"'
                echo ""
                
                echo "$JSON_START" | jq -r '.analysis.immediate_fixes[]? | "IMMEDIATE FIX: \(.priority) - \(.action)"'
                echo ""
                
                echo "$JSON_START" | jq -r '.analysis.recommendations[]? | "RECOMMENDATION (\(.category)): \(.recommendation) (Impact: \(.impact))"'
                echo ""
                
                echo "$JSON_START" | jq -r '.analysis.lessons_learned[]? | "LESSON: \(.)"'
                echo ""
                
                # Save the full response for artifacts
                echo "$ANALYSIS_TEXT" > analysis-results.txt
                print_status "Full analysis saved to analysis-results.txt"
                
            else
                print_warning "Could not extract JSON from response, showing raw analysis:"
                echo "$ANALYSIS_TEXT"
                echo "$ANALYSIS_TEXT" > analysis-results.txt
            fi
        else
            print_error "No response content found"
            cat bedrock-response.json
            exit 1
        fi
    else
        print_warning "jq not available, showing raw response:"
        cat bedrock-response.json
        cat bedrock-response.json > analysis-results.txt
    fi
    
    # Clean up temporary files
    rm -f "$TEMP_PROMPT_FILE" "$BEDROCK_PAYLOAD_FILE"
    
else
    print_error "Bedrock analysis failed"
    exit 1
fi
