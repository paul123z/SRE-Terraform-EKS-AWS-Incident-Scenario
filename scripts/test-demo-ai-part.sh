#!/bin/bash
# Test script to debug the AI analysis display part of incident-demo.sh

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

# Test the AI analysis part
echo "=== Testing AI Analysis Display Part ==="
echo ""

# Simulate the incident demo AI analysis section
INCIDENT_ID="test-incident-$(date +%Y%m%d-%H%M%S)"

print_status "Testing AI analysis with incident ID: $INCIDENT_ID"
echo ""

# Check if analysis script exists
if [ -f "./scripts/analyze-incident-bedrock.sh" ] && [ -x "./scripts/analyze-incident-bedrock.sh" ]; then
    print_status "Analysis script found and executable"
    
    print_status "Starting AI analysis..."
    ANALYSIS_OUTPUT=$(./scripts/analyze-incident-bedrock.sh "$INCIDENT_ID" 2>&1)
    ANALYSIS_EXIT_CODE=$?
    print_status "AI analysis completed with exit code: $ANALYSIS_EXIT_CODE"
    
    if [ $ANALYSIS_EXIT_CODE -eq 0 ]; then
        print_success "AI analysis completed successfully!"
        
        # Small delay to ensure file is written
        sleep 2
        
        # Find the most recent bedrock response file
        print_status "Searching for analysis files..."
        ls -la bedrock-analysis/bedrock_response_*.json 2>/dev/null || print_warning "No analysis files found"
        ANALYSIS_FILE=$(ls -t bedrock-analysis/bedrock_response_*.json 2>/dev/null | head -1)
        print_status "Found analysis file: $ANALYSIS_FILE"
        
        if [ -n "$ANALYSIS_FILE" ] && [ -f "$ANALYSIS_FILE" ]; then
            print_success "Analysis file found and accessible"
            
            # Display the analysis results
            echo ""
            print_header "🤖 AI-POWERED INCIDENT ANALYSIS RESULTS"
            echo ""
            
            # Extract and display the structured analysis if available
            if command -v jq &> /dev/null; then
                print_status "jq is available, attempting to parse and display results..."
                
                print_status "📊 INCIDENT SUMMARY:"
                INCIDENT_TYPE=$(jq -r '.content[0].text' "$ANALYSIS_FILE" | sed 's/```json//' | sed 's/```//' | jq -r '.analysis.incident_summary.type' 2>/dev/null || echo "Unknown")
                SEVERITY=$(jq -r '.content[0].text' "$ANALYSIS_FILE" | sed 's/```json//' | sed 's/```//' | jq -r '.analysis.incident_summary.severity' 2>/dev/null || echo "Unknown")
                DURATION=$(jq -r '.content[0].text' "$ANALYSIS_FILE" | sed 's/```json//' | sed 's/```//' | jq -r '.analysis.incident_summary.duration' 2>/dev/null || echo "Unknown")
                echo "  Type: $INCIDENT_TYPE"
                echo "  Severity: $SEVERITY"
                echo "  Duration: $DURATION"
                echo ""
                
                print_status "🔍 ROOT CAUSE ANALYSIS:"
                PRIMARY_CAUSE=$(jq -r '.content[0].text' "$ANALYSIS_FILE" | sed 's/```json//' | sed 's/```//' | jq -r '.analysis.root_cause_analysis.primary_cause' 2>/dev/null || echo "Unknown")
                echo "  Primary Cause: $PRIMARY_CAUSE"
                echo ""
                
                print_status "⚡ IMMEDIATE FIXES:"
                jq -r '.content[0].text' "$ANALYSIS_FILE" | sed 's/```json//' | sed 's/```//' | jq -r '.analysis.immediate_fixes[] | "  \(.priority | ascii_upcase): \(.action) - \(.description)"' 2>/dev/null || echo "  No immediate fixes found"
                echo ""
                
                print_success "✅ AI analysis results displayed above!"
                print_status "Full analysis saved to: $ANALYSIS_FILE"
                
            else
                print_warning "jq not available, showing raw analysis file:"
                cat "$ANALYSIS_FILE"
            fi
        else
            print_error "Analysis file not found or not accessible"
            print_warning "Analysis completed but display failed. Here's how to view the results:"
            echo ""
            print_status "📋 TO VIEW AI ANALYSIS RESULTS:"
            echo ""
            echo "1. Run the analysis display script:"
            echo "   ./scripts/test-analysis-display.sh"
            echo ""
            echo "2. Or view the raw analysis file:"
            echo "   cat $ANALYSIS_FILE"
            echo ""
            print_status "💡 TIP: The AI analysis provides structured recommendations including:"
            echo "   • Root cause analysis"
            echo "   • Immediate fixes with priorities"
            echo "   • Preventive measures with timelines"
            echo "   • Lessons learned"
            echo "   • Actionable recommendations by category"
            echo ""
        fi
    else
        print_error "AI analysis failed with exit code $ANALYSIS_EXIT_CODE"
        print_warning "Raw output:"
        echo "$ANALYSIS_OUTPUT"
    fi
else
    print_warning "Analysis script not found. Please run manually:"
    print_status "./scripts/analyze-incident-bedrock.sh $INCIDENT_ID"
fi

echo ""
print_success "=== Test completed ==="
