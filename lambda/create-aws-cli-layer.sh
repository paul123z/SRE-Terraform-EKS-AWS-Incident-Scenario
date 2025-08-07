#!/bin/bash

# Create AWS CLI Lambda Layer
# This script creates a Lambda layer with AWS CLI for Bedrock calls

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
LAYER_DIR="lambda/aws-cli-layer"
ZIP_FILE="lambda/aws-cli-layer.zip"

print_status "Creating AWS CLI Lambda Layer..."

# Create layer directory structure
mkdir -p "$LAYER_DIR/aws-cli"

# Download AWS CLI v2 for Linux x86_64
print_status "Downloading AWS CLI v2..."
curl -L "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$LAYER_DIR/awscli.zip"

# Extract AWS CLI
print_status "Extracting AWS CLI..."
cd "$LAYER_DIR"
unzip -q awscli.zip
cd ../..

# Move AWS CLI to layer directory
print_status "Installing AWS CLI to layer..."
"$LAYER_DIR/aws/install" -i "$LAYER_DIR/aws-cli" -b "$LAYER_DIR/aws-cli/bin"

# Create a wrapper script
print_status "Creating AWS CLI wrapper..."
cat > "$LAYER_DIR/aws-cli/aws" << 'EOF'
#!/bin/bash
# AWS CLI wrapper for Lambda
export PATH="/opt/aws-cli/bin:$PATH"
exec /opt/aws-cli/bin/aws "$@"
EOF

chmod +x "$LAYER_DIR/aws-cli/aws"

# Create the layer ZIP
print_status "Creating layer ZIP file..."
cd "$LAYER_DIR"
zip -r "../aws-cli-layer.zip" aws-cli/
cd ../..

print_success "AWS CLI Lambda layer created: $ZIP_FILE"
print_status "Layer size: $(du -h "$ZIP_FILE" | cut -f1)"

# Clean up
rm -rf "$LAYER_DIR/aws" "$LAYER_DIR/awscli.zip"

print_status "Next steps:"
print_status "1. Upload this layer to AWS Lambda"
print_status "2. Attach it to your Lambda function"
print_status "3. Update Lambda function to use /opt/aws-cli/aws"
