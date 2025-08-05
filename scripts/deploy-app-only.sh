#!/bin/bash

# Deploy Application Only Script
# This script deploys only the application from ECR

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="eu-central-1"
CLUSTER_NAME="sre-incident-demo-cluster"
APP_NAME="sre-demo-app"
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
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed"
        exit 1
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    
    # Check Helm
    if ! command -v helm &> /dev/null; then
        print_error "Helm is not installed"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured"
        exit 1
    fi
    
    print_success "All prerequisites are satisfied"
}

# Function to update kubeconfig
update_kubeconfig() {
    print_status "Updating kubeconfig..."
    aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
    print_success "Kubeconfig updated"
}

# Function to deploy application
deploy_application() {
    print_status "Deploying application..."
    
    # Get ECR registry
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
    
    # Deploy using Helm
    helm upgrade --install $APP_NAME ./helm/sre-demo-app \
        --set image.repository=$ECR_REGISTRY/$ECR_REPOSITORY \
        --set image.tag=latest \
        --namespace default \
        --wait \
        --timeout 5m
    
    print_success "Application deployed successfully"
}

# Function to verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Wait for pods to be ready
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=$APP_NAME --timeout=300s
    
    # Show pod status
    print_status "Pod status:"
    kubectl get pods -l app.kubernetes.io/name=$APP_NAME
    
    # Show service status
    print_status "Service status:"
    kubectl get svc $APP_NAME
    
    # Get service URL
    SERVICE_URL=$(kubectl get svc $APP_NAME -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    if [ -n "$SERVICE_URL" ]; then
        print_success "Application URL: http://$SERVICE_URL"
    else
        print_warning "Service URL not available yet (may take a few minutes)"
    fi
}

# Main function
main() {
    print_status "Starting application deployment..."
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Update kubeconfig
    update_kubeconfig
    
    # Deploy application
    deploy_application
    
    # Verify deployment
    verify_deployment
    
    print_success "Application deployment completed successfully!"
}

# Run main function
main "$@" 