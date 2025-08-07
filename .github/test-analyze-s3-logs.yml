#!/bin/bash

# Test script for analyze-s3-logs GitHub Actions workflow
# This simulates the key parts of the workflow locally

set -e

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

# Test URL parsing function
test_url_parsing() {
    print_header "Testing S3 URL Parsing"
    
    # Test cases
    TEST_URLS=(
        "s3://sre-incident-demo-incident-logs-l35a3g7s/incidents/demo-incident-20250807-222634/incident-demo-incident-20250807-222634.log"
        "https://sre-incident-demo-incident-logs-l35a3g7s.s3.eu-central-1.amazonaws.com/incidents/demo-incident-20250807-222634/incident-demo-incident-20250807-222634.log"
    )
    
    for S3_URL in "${TEST_URLS[@]}"; do
        echo "Testing URL: $S3_URL"
        
        # Parse URL (same logic as GitHub workflow)
        if [[ "$S3_URL" == s3://* ]]; then
            BUCKET=$(echo "$S3_URL" | sed 's|s3://||' | cut -d'/' -f1)
            KEY=$(echo "$S3_URL" | sed 's|s3://[^/]*/||')
        elif [[ "$S3_URL" == https://*.s3.*.amazonaws.com/* ]]; then
            BUCKET=$(echo "$S3_URL" | sed 's|https://||' | cut -d'.' -f1)
            KEY=$(echo "$S3_URL" | sed 's|https://[^/]*/||')
        else
            print_error "Invalid S3 URL format: $S3_URL"
            continue
        fi
        
        echo "  Bucket: $BUCKET"
        echo "  Key: $KEY"
        echo ""
    done
}

# Test AWS CLI and Bedrock access
test_aws_bedrock() {
    print_header "Testing AWS CLI and Bedrock Access"
    
    # Check AWS CLI
    if command -v aws &> /dev/null; then
        print_success "AWS CLI is installed"
        aws --version
    else
        print_error "AWS CLI not found"
        return 1
    fi
    
    # Check Bedrock access
    print_status "Testing Bedrock access..."
    if aws bedrock list-foundation-models --region us-west-1 --query 'modelSummaries[?providerName==`Anthropic`]' --output table 2>/dev/null; then
        print_success "Bedrock access confirmed"
    else
        print_warning "Bedrock access failed - check credentials and permissions"
    fi
}

# Test log file analysis (using local file)
test_analysis() {
    print_header "Testing Log Analysis Logic"
    
    # Use a local log file for testing
    LOCAL_LOG="/tmp/incident-logs/incident-demo-incident-20250807-222634.log"
    
    if [ -f "$LOCAL_LOG" ]; then
        print_status "Using local log file: $LOCAL_LOG"
        
        # Read log content
        LOGS_CONTENT=$(cat "$LOCAL_LOG")
        LOG_SIZE=$(echo "$LOGS_CONTENT" | wc -c)
        
        print_status "Log content loaded (size: $LOG_SIZE characters)"
        
        # Create simplified analysis prompt
        ANALYSIS_PROMPT="Analyze this Kubernetes incident log and provide a brief summary. Focus on the main issue and one key recommendation. Log: ${LOGS_CONTENT:0:1000}..."
        
        print_status "Analysis prompt created (truncated for testing)"
        print_success "Analysis logic test completed"
    else
        print_warning "Local log file not found, skipping analysis test"
    fi
}

# Main test function
main() {
    print_header "🧪 ANALYZE-S3-LOGS WORKFLOW TEST"
    echo ""
    
    print_status "Testing analyze-s3-logs GitHub Actions workflow components..."
    echo ""
    
    # Test URL parsing
    test_url_parsing
    echo ""
    
    # Test AWS/Bedrock access
    test_aws_bedrock
    echo ""
    
    # Test analysis logic
    test_analysis
    echo ""
    
    print_success "✅ All tests completed!"
    echo ""
    print_status "Next steps:"
    print_status "1. Add AWS credentials to GitHub Secrets"
    print_status "2. Commit the workflow files"
    print_status "3. Test the workflow manually in GitHub Actions"
}

# Run tests
main "$@"
