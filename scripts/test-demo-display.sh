#!/bin/bash
# Test script to verify demo display logic

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

# Test the demo's display logic
echo "Testing demo display logic..."

# Find the most recent bedrock response file
print_status "Searching for analysis files..."
ls -la bedrock-analysis/bedrock_response_*.json 2>/dev/null || print_warning "No analysis files found"
ANALYSIS_FILE=$(ls -t bedrock-analysis/bedrock_response_*.json 2>/dev/null | head -1)
print_status "Found analysis file: $ANALYSIS_FILE"

if [ -n "$ANALYSIS_FILE" ] && [ -f "$ANALYSIS_FILE" ]; then
    print_success "Analysis file found and accessible"
    
    if command -v jq &> /dev/null; then
        print_status "jq is available, testing parsing..."
        
        # Test parsing
        INCIDENT_TYPE=$(jq -r '.content[0].text' "$ANALYSIS_FILE" | sed 's/```json//' | sed 's/```//' | jq -r '.analysis.incident_summary.type' 2>/dev/null || echo "Unknown")
        print_status "Parsed incident type: $INCIDENT_TYPE"
        
        if [ "$INCIDENT_TYPE" != "Unknown" ]; then
            print_success "Parsing successful! Demo display should work."
        else
            print_error "Parsing failed! Demo display will not work."
        fi
    else
        print_warning "jq not available"
    fi
else
    print_error "Analysis file not found or not accessible"
fi

echo "Test completed."
