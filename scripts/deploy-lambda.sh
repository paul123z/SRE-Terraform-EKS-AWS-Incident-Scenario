#!/bin/bash

# Update Lambda Function Script
# This script updates the Lambda function with the latest code

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

print_header() {
    echo -e "${YELLOW}$1${NC}"
}

print_header "================================
UPDATING LAMBDA FUNCTION
================================"

print_status "Updating Lambda function with latest code..."

# Set AWS CLI to not use pager
export AWS_PAGER=""

# Check if ZIP file exists
if [ ! -f "lambda/incident-analyzer.zip" ]; then
    print_error "ZIP file not found. Run ./scripts/build-lambda.sh first"
    exit 1
fi

# Update Lambda function
if /usr/local/aws-cli/v2/current/bin/aws lambda update-function-code \
    --function-name sre-incident-demo-incident-analyzer \
    --zip-file fileb://lambda/incident-analyzer.zip \
    --region eu-central-1 \
    --output text; then
    
    print_success "Lambda function updated successfully!"
    print_status "You can now test with: ./scripts/debug-lambda.sh"
    
else
    print_error "Failed to update Lambda function"
    exit 1
fi

print_header "================================
NEXT STEPS
================================"
print_status "Test the updated function:"
print_status "./scripts/debug-lambda.sh"
print_status ""
print_status "Or run the full demo:"
print_status "./scripts/incident-demo.sh" 