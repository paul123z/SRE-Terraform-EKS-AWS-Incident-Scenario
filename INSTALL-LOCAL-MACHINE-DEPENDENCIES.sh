fi#!/bin/bash

# INSTALL-LOCAL-MACHINE-DEPENDENCIES.sh
# This script automatically installs all required dependencies for the SRE Terraform EKS AWS Incident Scenario project on WSL/Ubuntu.
# It checks if each tool is already installed and skips it if found, allowing you to safely re-run the script if any installation fails.
# Simply run this script once and it will set up Git, AWS CLI, Terraform, kubectl, Helm, Docker, Python, and pip with the correct versions.

# set -e disabled to allow continuing after individual package failures
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check version and compare
version_check() {
    local tool=$1
    local current=$2
    local required=$3
    
    if [ -n "$current" ]; then
        print_success "$tool is installed (version: $current)"
        if [ "$current" != "$required" ]; then
            print_warning "Current version ($current) differs from project version ($required), but continuing..."
        fi
        return 0
    else
        return 1
    fi
}

print_header "SRE Project Dependencies Installer"
print_status "Starting dependency installation for SRE Terraform EKS AWS Incident Scenario project..."
echo ""

# Update package list
print_status "Updating package list..."
sudo apt-get update -qq

echo ""
print_header "1. Installing Git"

if command_exists git; then
    GIT_VERSION=$(git --version | cut -d' ' -f3)
    version_check "Git" "$GIT_VERSION" "2.25.1+"
else
    print_status "Installing Git..."
    sudo apt-get install -y git
    if command_exists git; then
        GIT_VERSION=$(git --version | cut -d' ' -f3)
        print_success "Git installed successfully (version: $GIT_VERSION)"
    else
        print_error "Git installation failed"
    fi
fi

echo ""
print_header "2. Installing Python and pip"

if command_exists python3; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    version_check "Python3" "$PYTHON_VERSION" "3.13.4"
else
    print_status "Installing Python3..."
    sudo apt-get install -y python3 python3-pip python3-venv
fi

if command_exists pip3; then
    PIP_VERSION=$(pip3 --version | cut -d' ' -f2)
    version_check "pip3" "$PIP_VERSION" "25.0.1"
else
    print_status "Installing pip3..."
    sudo apt-get install -y python3-pip
    if command_exists pip3; then
        PIP_VERSION=$(pip3 --version | cut -d' ' -f2)
        print_success "pip3 installed successfully (version: $PIP_VERSION)"
    else
        print_error "pip3 installation failed"
    fi
fi

echo ""
print_header "3. Installing AWS CLI v2"

if command_exists aws; then
    AWS_VERSION=$(aws --version 2>&1 | cut -d'/' -f2 | cut -d' ' -f1)
    if version_check "AWS CLI" "$AWS_VERSION" "2.28.2+"; then
        print_status "AWS CLI v2 is already installed"
    fi
else
    print_status "Installing AWS CLI v2..."
    # Install required packages
    sudo apt-get install -y curl unzip
    
    # Download and install AWS CLI v2
    cd /tmp
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install --update
    
    # Clean up
    rm -rf awscliv2.zip aws/
    cd - > /dev/null
    
    if command_exists aws; then
        AWS_VERSION=$(aws --version 2>&1 | cut -d'/' -f2 | cut -d' ' -f1)
        print_success "AWS CLI v2 installed successfully (version: $AWS_VERSION)"
    else
        print_error "AWS CLI installation failed"
    fi
fi

echo ""
print_header "4. Installing Terraform"

if command_exists terraform; then
    TERRAFORM_VERSION=$(terraform version | head -n1 | cut -d'v' -f2)
    version_check "Terraform" "$TERRAFORM_VERSION" "1.8.4+"
else
    print_status "Installing Terraform..."
    # Install required packages
    sudo apt-get install -y gnupg software-properties-common
    
    # Add HashiCorp GPG key using curl instead of wget
    curl -fsSL https://apt.releases.hashicorp.com/gpg | \
        gpg --dearmor | \
        sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
    
    # Add HashiCorp repository
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
        https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
        sudo tee /etc/apt/sources.list.d/hashicorp.list
    
    # Update and install
    sudo apt-get update -qq
    sudo apt-get install -y terraform
    
    if command_exists terraform; then
        TERRAFORM_VERSION=$(terraform version | head -n1 | cut -d'v' -f2)
        print_success "Terraform installed successfully (version: $TERRAFORM_VERSION)"
    else
        print_error "Terraform installation failed"
    fi
fi

echo ""
print_header "5. Installing kubectl"

if command_exists kubectl; then
    KUBECTL_VERSION=$(kubectl version --client --output=yaml 2>/dev/null | grep gitVersion | cut -d'"' -f4 | sed 's/v//')
    version_check "kubectl" "$KUBECTL_VERSION" "1.26.1+"
else
    print_status "Installing kubectl..."
    # Download kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    
    # Install kubectl
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    
    if command_exists kubectl; then
        KUBECTL_VERSION=$(kubectl version --client --output=yaml 2>/dev/null | grep gitVersion | cut -d'"' -f4 | sed 's/v//')
        print_success "kubectl installed successfully (version: $KUBECTL_VERSION)"
    else
        print_error "kubectl installation failed"
    fi
fi

echo ""
print_header "6. Installing Helm"

if command_exists helm; then
    HELM_VERSION=$(helm version --short | cut -d'v' -f2 | cut -d'+' -f1)
    version_check "Helm" "$HELM_VERSION" "3.18.4+"
else
    print_status "Installing Helm..."
    # Download and install Helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    
    if command_exists helm; then
        HELM_VERSION=$(helm version --short | cut -d'v' -f2 | cut -d'+' -f1)
        print_success "Helm installed successfully (version: $HELM_VERSION)"
    else
        print_error "Helm installation failed"
    fi
fi

echo ""
print_header "7. Installing Docker"

if command_exists docker; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | sed 's/,//')
    version_check "Docker" "$DOCKER_VERSION" "25.0.3+"
else
    print_status "Installing Docker..."
    # Install required packages
    sudo apt-get install -y ca-certificates curl
    
    # Add Docker GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update and install Docker
    sudo apt-get update -qq
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    if command_exists docker; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | sed 's/,//')
        print_success "Docker installed successfully (version: $DOCKER_VERSION)"
        print_warning "You may need to log out and log back in for Docker group membership to take effect"
    else
        print_error "Docker installation failed"
    fi
fi

echo ""
print_header "8. Installing Additional Tools"

# Install jq for JSON processing
if ! command_exists jq; then
    print_status "Installing jq..."
    sudo apt-get install -y jq
fi

# Install dos2unix for line ending conversion
if ! command_exists dos2unix; then
    print_status "Installing dos2unix..."
    sudo apt-get install -y dos2unix
fi

# Install tree for directory visualization
if ! command_exists tree; then
    print_status "Installing tree..."
    sudo apt-get install -y tree
fi

echo ""
print_header "Installation Summary"

print_status "Checking final installation status..."
echo ""

# Final verification
echo "| Tool | Status | Version |"
echo "|------|--------|---------|"

if command_exists git; then
    GIT_VERSION=$(git --version | cut -d' ' -f3)
    echo "| Git | ✅ Installed | $GIT_VERSION |"
else
    echo "| Git | ❌ Missing | - |"
fi

if command_exists aws; then
    AWS_VERSION=$(aws --version 2>&1 | cut -d'/' -f2 | cut -d' ' -f1)
    echo "| AWS CLI | ✅ Installed | $AWS_VERSION |"
else
    echo "| AWS CLI | ❌ Missing | - |"
fi

if command_exists terraform; then
    TERRAFORM_VERSION=$(terraform version | head -n1 | cut -d'v' -f2)
    echo "| Terraform | ✅ Installed | $TERRAFORM_VERSION |"
else
    echo "| Terraform | ❌ Missing | - |"
fi

if command_exists kubectl; then
    KUBECTL_VERSION=$(kubectl version --client --output=yaml 2>/dev/null | grep gitVersion | cut -d'"' -f4 | sed 's/v//')
    echo "| kubectl | ✅ Installed | $KUBECTL_VERSION |"
else
    echo "| kubectl | ❌ Missing | - |"
fi

if command_exists helm; then
    HELM_VERSION=$(helm version --short | cut -d'v' -f2 | cut -d'+' -f1)
    echo "| Helm | ✅ Installed | $HELM_VERSION |"
else
    echo "| Helm | ❌ Missing | - |"
fi

if command_exists docker; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | sed 's/,//')
    echo "| Docker | ✅ Installed | $DOCKER_VERSION |"
else
    echo "| Docker | ❌ Missing | - |"
fi

if command_exists python3; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    echo "| Python3 | ✅ Installed | $PYTHON_VERSION |"
else
    echo "| Python3 | ❌ Missing | - |"
fi

if command_exists pip3; then
    PIP_VERSION=$(pip3 --version | cut -d' ' -f2)
    echo "| pip3 | ✅ Installed | $PIP_VERSION |"
else
    echo "| pip3 | ❌ Missing | - |"
fi

echo ""
print_success "🎉 Installation completed!"
print_status "Next steps:"
echo "  1. Configure AWS credentials: aws configure"
echo "  2. If Docker was installed, log out and log back in to use Docker without sudo"
echo "  3. Run your SRE project scripts: ./scripts/deploy.sh"
echo ""
print_status "If any tool failed to install, fix the issue and re-run this script."
