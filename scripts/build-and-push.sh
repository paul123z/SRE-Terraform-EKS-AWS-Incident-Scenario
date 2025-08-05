#!/bin/bash

# Build and Push Script
# This script builds the Docker image and pushes it to ECR

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="eu-central-1"
ECR_REPOSITORY="sre-demo-app"

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

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null && ! /usr/local/bin/aws --version &> /dev/null; then
        print_error "AWS CLI is not installed"
        exit 1
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    
    # Check AWS credentials
    AWS_CMD=$(command -v aws || echo "/usr/local/bin/aws")
    if ! $AWS_CMD sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured"
        exit 1
    fi
    
    print_success "All prerequisites are satisfied"
}

# Function to get AWS account ID
get_aws_account_id() {
    # Use full path if aws not in PATH
    AWS_CMD=$(command -v aws || echo "/usr/local/bin/aws")
    AWS_ACCOUNT_ID=$($AWS_CMD sts get-caller-identity --query Account --output text)
    print_status "AWS Account ID: $AWS_ACCOUNT_ID"
}

# Function to build and push image
build_and_push() {
    print_status "Building Docker image..."
    
    # Build the image
    cd app
    docker build -t sre-demo-app .
    cd ..
    
    print_success "Docker image built successfully"
    
    # Get ECR registry
    ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
    
    # Login to ECR
    print_status "Logging in to ECR..."
    $AWS_CMD ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
    
    # Tag the image
    print_status "Tagging image..."
    docker tag sre-demo-app:latest $ECR_REGISTRY/$ECR_REPOSITORY:latest
    
    # Push to ECR
    print_status "Pushing image to ECR..."
    docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
    
    print_success "Image pushed successfully to ECR"
}

# Function to redeploy application
redeploy_application() {
    print_status "Redeploying application..."
    
    # Restart deployment to pull new image
    kubectl rollout restart deployment sre-demo-app
    
    # Wait for deployment to be ready
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=sre-demo-app --timeout=300s
    
    print_success "Application redeployed successfully"
}

# Function to verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Check pod status
    kubectl get pods -l app.kubernetes.io/name=sre-demo-app
    
    # Test curl in the new pod
    POD_NAME=$(kubectl get pods -l app.kubernetes.io/name=sre-demo-app -o jsonpath='{.items[0].metadata.name}')
    print_status "Testing curl in pod: $POD_NAME"
    kubectl exec -it $POD_NAME -- curl --version || print_warning "curl not available in pod"
    
    print_success "Deployment verification completed"
}

# Main function
main() {
    print_status "Starting build and push process..."
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Get AWS account ID
    get_aws_account_id
    
    # Build and push
    build_and_push
    
    # Ask if user wants to redeploy
    echo ""
    read -p "Do you want to redeploy the application? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        redeploy_application
        verify_deployment
    else
        print_status "Skipping redeployment. You can redeploy manually with: kubectl rollout restart deployment sre-demo-app"
    fi
    
    print_success "Build and push completed successfully!"
}

# Run main function
main "$@" 