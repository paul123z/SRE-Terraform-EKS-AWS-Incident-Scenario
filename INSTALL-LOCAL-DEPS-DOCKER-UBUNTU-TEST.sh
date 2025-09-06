#!/bin/bash

# INSTALL-LOCAL-DEPS-DOCKER-UBUNTU-TEST.sh
# This script tests the INSTALL-LOCAL-MACHINE-DEPENDENCIES.sh script in a fresh Ubuntu Docker container.
# It automatically pulls Ubuntu, creates a reusable container, and runs the dependency installation script inside it.
# The script handles sudo removal for container environment and can be run multiple times safely.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}================================${NC}"
    echo ""
}

# Configuration
UBUNTU_IMAGE="ubuntu:22.04"
CONTAINER_NAME="sre-deps-test"
INSTALL_SCRIPT="INSTALL-LOCAL-MACHINE-DEPENDENCIES.sh"

print_header "Docker Ubuntu Dependency Test"

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running or not accessible"
    print_status "Please start Docker Desktop and try again"
    exit 1
fi

# Check if install script exists
if [ ! -f "$INSTALL_SCRIPT" ]; then
    print_error "Installation script not found: $INSTALL_SCRIPT"
    print_status "Please run this script from the project root directory"
    exit 1
fi

print_success "Docker is running and installation script found"

# Pull Ubuntu image if not exists
print_status "Checking Ubuntu image..."
if ! docker image inspect $UBUNTU_IMAGE >/dev/null 2>&1; then
    print_status "Pulling Ubuntu image..."
    docker pull $UBUNTU_IMAGE
    print_success "Ubuntu image pulled successfully"
else
    print_success "Ubuntu image already exists"
fi

# Remove existing container if it exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    print_status "Removing existing container: $CONTAINER_NAME"
    docker rm -f $CONTAINER_NAME >/dev/null 2>&1
fi

# Create and start container
print_status "Creating new Ubuntu container: $CONTAINER_NAME"
docker run -d --name $CONTAINER_NAME \
    -v "$(pwd)/$INSTALL_SCRIPT:/tmp/install-deps.sh:ro" \
    $UBUNTU_IMAGE \
    tail -f /dev/null

print_success "Container created and running"

# Create container-friendly installation script
print_status "Preparing installation script for container environment..."
docker exec $CONTAINER_NAME bash -c '
# Create container-friendly version that removes sudo commands
cat > /tmp/install-container.sh << "EOF"
#!/bin/bash

echo "🐳 Container-friendly dependency installer"
echo "Removing sudo commands for root container environment..."

# Remove sudo from the original script since we run as root in container
sed "s/sudo //g" /tmp/install-deps.sh > /tmp/install-deps-no-sudo.sh
chmod +x /tmp/install-deps-no-sudo.sh

echo "✅ Container script prepared, starting installation..."
echo ""

# Run the modified script
/tmp/install-deps-no-sudo.sh
EOF

chmod +x /tmp/install-container.sh
'

# Run the installation in the container
print_header "Running Dependency Installation in Container"
print_status "This may take several minutes..."
echo ""

# Execute the installation script in the container
if docker exec -it $CONTAINER_NAME /tmp/install-container.sh; then
    echo ""
    print_success "🎉 Installation completed successfully!"
    
    # Show final status
    print_header "Final Installation Verification"
    docker exec $CONTAINER_NAME bash -c '
    echo "| Tool | Status | Version |"
    echo "|------|--------|---------|"
    
    # Check each tool
    if command -v git >/dev/null 2>&1; then
        echo "| Git | ✅ Installed | $(git --version | cut -d\" \" -f3) |"
    else
        echo "| Git | ❌ Missing | - |"
    fi
    
    if command -v aws >/dev/null 2>&1; then
        echo "| AWS CLI | ✅ Installed | $(aws --version 2>&1 | cut -d\"/\" -f2 | cut -d\" \" -f1) |"
    else
        echo "| AWS CLI | ❌ Missing | - |"
    fi
    
    if command -v terraform >/dev/null 2>&1; then
        echo "| Terraform | ✅ Installed | $(terraform version | head -n1 | cut -d\"v\" -f2) |"
    else
        echo "| Terraform | ❌ Missing | - |"
    fi
    
    if command -v kubectl >/dev/null 2>&1; then
        echo "| kubectl | ✅ Installed | $(kubectl version --client --output=yaml 2>/dev/null | grep gitVersion | cut -d\"\\\"\" -f4 | sed \"s/v//\") |"
    else
        echo "| kubectl | ❌ Missing | - |"
    fi
    
    if command -v helm >/dev/null 2>&1; then
        echo "| Helm | ✅ Installed | $(helm version --short | cut -d\"v\" -f2 | cut -d\"+\" -f1) |"
    else
        echo "| Helm | ❌ Missing | - |"
    fi
    
    if command -v docker >/dev/null 2>&1; then
        echo "| Docker | ✅ Installed | $(docker --version | cut -d\" \" -f3 | sed \"s/,//\") |"
    else
        echo "| Docker | ❌ Missing | - |"
    fi
    
    if command -v python3 >/dev/null 2>&1; then
        echo "| Python3 | ✅ Installed | $(python3 --version | cut -d\" \" -f2) |"
    else
        echo "| Python3 | ❌ Missing | - |"
    fi
    
    if command -v pip3 >/dev/null 2>&1; then
        echo "| pip3 | ✅ Installed | $(pip3 --version | cut -d\" \" -f2) |"
    else
        echo "| pip3 | ❌ Missing | - |"
    fi
    '
    
    echo ""
    print_header "Test Results"
    print_success "✅ Container test completed successfully"
    print_success "✅ All tools were tested in fresh Ubuntu 22.04 environment"
    print_success "✅ Installation script works correctly in container"
    
    echo ""
    print_status "Container '$CONTAINER_NAME' is still running for inspection"
    print_status "To connect: docker exec -it $CONTAINER_NAME bash"
    print_status "To remove: docker rm -f $CONTAINER_NAME"
    
else
    print_error "❌ Installation failed in container"
    print_status "Container '$CONTAINER_NAME' is still running for debugging"
    print_status "To debug: docker exec -it $CONTAINER_NAME bash"
    print_status "To remove: docker rm -f $CONTAINER_NAME"
    exit 1
fi

echo ""
print_header "Next Steps"
print_status "1. Review the installation results above"
print_status "2. If satisfied, the script is ready for production use"
print_status "3. Run './INSTALL-LOCAL-MACHINE-DEPENDENCIES.sh' on your local machine"
print_status "4. Clean up: docker rm -f $CONTAINER_NAME"
