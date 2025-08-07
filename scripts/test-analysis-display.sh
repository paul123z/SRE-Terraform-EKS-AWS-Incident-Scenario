#!/bin/bash
# Test script to display AI analysis results
# This simulates what the incident-demo.sh script will do

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

# Find the most recent bedrock response file
ANALYSIS_FILE=$(ls -t bedrock-analysis/bedrock_response_*.json 2>/dev/null | head -1)

if [ -n "$ANALYSIS_FILE" ] && [ -f "$ANALYSIS_FILE" ]; then
    print_success "Found analysis file: $ANALYSIS_FILE"
    
    if command -v jq &> /dev/null; then
        echo ""
        print_header "🤖 AI-POWERED INCIDENT ANALYSIS RESULTS"
        echo ""
        
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
        
        print_status "🛡️ PREVENTIVE MEASURES:"
        jq -r '.content[0].text' "$ANALYSIS_FILE" | sed 's/```json//' | sed 's/```//' | jq -r '.analysis.preventive_measures[] | "  \(.measure): \(.implementation) (Timeline: \(.timeline))"' 2>/dev/null || echo "  No preventive measures found"
        echo ""
        
        print_status "📚 LESSONS LEARNED:"
        jq -r '.content[0].text' "$ANALYSIS_FILE" | sed 's/```json//' | sed 's/```//' | jq -r '.analysis.lessons_learned[] | "  • \(.)"' 2>/dev/null || echo "  No lessons learned found"
        echo ""
        
        print_status "💡 RECOMMENDATIONS:"
        jq -r '.content[0].text' "$ANALYSIS_FILE" | sed 's/```json//' | sed 's/```//' | jq -r '.analysis.recommendations[] | "  \(.category | ascii_upcase): \(.recommendation) (Impact: \(.impact))"' 2>/dev/null || echo "  No recommendations found"
        echo ""
        
        print_success "✅ AI analysis results displayed above!"
        print_status "Full analysis saved to: $ANALYSIS_FILE"
    else
        print_warning "jq not available, showing raw analysis file:"
        cat "$ANALYSIS_FILE"
    fi
else
    print_error "No analysis files found in bedrock-analysis directory"
    exit 1
fi
