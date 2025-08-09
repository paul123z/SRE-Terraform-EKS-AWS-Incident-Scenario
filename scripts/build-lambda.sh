#!/bin/bash

# Build Lambda function for AI incident analysis
# This script packages the Python Lambda function with dependencies

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

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
LAMBDA_DIR="lambda"
BUILD_DIR="lambda/build"
ZIP_FILE="lambda/incident-analyzer.zip"

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Python is installed
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed"
        exit 1
    fi
    
    # Check if pip is installed
    if ! command -v pip3 &> /dev/null; then
        print_error "pip3 is not installed"
        exit 1
    fi
    
    print_success "Prerequisites are satisfied"
}

# Function to create build directory
create_build_dir() {
    print_status "Creating build directory..."
    
    # Remove existing build directory
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
    fi
    
    # Create new build directory
    mkdir -p "$BUILD_DIR"
    
    print_success "Build directory created"
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing Python dependencies..."
    
    # Create requirements.txt if it doesn't exist
    if [ ! -f "$LAMBDA_DIR/requirements.txt" ]; then
        cat > "$LAMBDA_DIR/requirements.txt" << EOF
boto3>=1.26.0
botocore>=1.29.0
EOF
        print_status "Created requirements.txt"
    fi
    
    # Install dependencies to build directory
    pip3 install -r "$LAMBDA_DIR/requirements.txt" -t "$BUILD_DIR" --no-cache-dir
    
    print_success "Dependencies installed"
}

# Function to copy Lambda function
copy_lambda_function() {
    print_status "Copying Lambda function..."
    
    # Copy the main Lambda function
    cp "$LAMBDA_DIR/incident-analyzer.py" "$BUILD_DIR/index.py"
    
    print_success "Lambda function copied"
}

# Function to create ZIP package
create_zip_package() {
    print_status "Creating ZIP package..."
    
    # Remove existing ZIP file
    if [ -f "$ZIP_FILE" ]; then
        rm "$ZIP_FILE"
    fi
    
    # Create ZIP file
    cd "$BUILD_DIR"
    zip -r "../incident-analyzer.zip" .
    cd - > /dev/null
    
    print_success "ZIP package created: $ZIP_FILE"
}

# Function to show package info
show_package_info() {
    print_status "Package information:"
    echo "ZIP file: $ZIP_FILE"
    echo "Size: $(du -h "$ZIP_FILE" | cut -f1)"
    echo "Contents:"
    unzip -l "$ZIP_FILE" | head -20
    echo "..."
}

# Function to clean up
cleanup() {
    print_status "Cleaning up build directory..."
    
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
    fi
    
    print_success "Cleanup completed"
}

# Main function
main() {
    print_status "Building Lambda function for AI incident analysis..."
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Create build directory
    create_build_dir
    
    # Install dependencies
    install_dependencies
    
    # Copy Lambda function
    copy_lambda_function
    
    # Create ZIP package
    create_zip_package
    
    # Show package info
    show_package_info
    
    # Clean up
    cleanup
    
    echo ""
    print_success "Lambda function built successfully!"
    print_status "Next steps:"
    echo "1. Run: terraform apply (to deploy infrastructure)"
    echo "2. Run: ./scripts/incident-demo.sh (to trigger incident)"
    echo "3. Run: ./scripts/analyze-incident.sh (to analyze with AI)"
}

# Run main function
main "$@" 