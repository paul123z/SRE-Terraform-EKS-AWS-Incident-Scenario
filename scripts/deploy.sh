#!/bin/bash

# SRE Demo Deployment Script
# This script automates the entire deployment process

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
ECR_REPOSITORY="sre-demo-app"
APP_NAME="sre-demo-app"
NAMESPACE="default"

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
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed"
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
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured"
        exit 1
    fi
    
    print_success "All prerequisites are satisfied"
}

# Function to get AWS account ID
get_aws_account_id() {
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    print_status "AWS Account ID: $AWS_ACCOUNT_ID"
}

# Function to create ECR repository
create_ecr_repository() {
    print_status "Creating ECR repository..."
    
    if ! aws ecr describe-repositories --repository-names $ECR_REPOSITORY --region $AWS_REGION &> /dev/null; then
        aws ecr create-repository --repository-name $ECR_REPOSITORY --region $AWS_REGION
        print_success "ECR repository created"
    else
        print_status "ECR repository already exists"
    fi
}

# Function to deploy infrastructure
deploy_infrastructure() {
    print_status "Deploying infrastructure with Terraform..."
    
    cd terraform
    
    # Initialize Terraform
    terraform init
    
    # Plan the deployment
    print_status "Planning Terraform deployment..."
    terraform plan -out=tfplan
    
    # Apply the deployment
    print_status "Applying Terraform deployment..."
    terraform apply tfplan
    
    # Get cluster info
    print_status "Updating kubeconfig..."
    aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
    
    cd ..
    
    print_success "Infrastructure deployed successfully"
}

# Function to build and push application
build_and_push_app() {
    print_status "Building and pushing application..."
    
    cd app
    
    # Build the Docker image
    print_status "Building Docker image..."
    docker build -t $ECR_REPOSITORY .
    
    # Tag the image
    docker tag $ECR_REPOSITORY:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest
    
    # Login to ECR
    print_status "Logging in to ECR..."
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
    
    # Push the image
    print_status "Pushing image to ECR..."
    docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest
    
    cd ..
    
    print_success "Application built and pushed successfully"
}

# Function to deploy application
deploy_application() {
    print_status "Deploying application with Helm..."
    
    cd helm/sre-demo-app
    
    # Install the application
    helm upgrade --install $APP_NAME . \
        --set image.repository=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY \
        --set image.tag=latest \
        --namespace $NAMESPACE \
        --create-namespace \
        --wait \
        --timeout 5m
    
    cd ../..
    
    print_success "Application deployed successfully"
}

# Function to setup monitoring
setup_monitoring() {
    print_status "Setting up monitoring..."
    
    # Add Prometheus Helm repository
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    
    # Install Prometheus with Grafana
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        -f monitoring/prometheus-values.yaml \
        --namespace monitoring \
        --create-namespace \
        --wait \
        --timeout 10m
    
    print_success "Monitoring setup completed"
}

# Function to verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Check if pods are running
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=$APP_NAME -n $NAMESPACE --timeout=300s
    
    # Check service
    kubectl get svc $APP_NAME -n $NAMESPACE
    
    # Check HPA
    kubectl get hpa -n $NAMESPACE
    
    # Get service URL
    SERVICE_URL=$(kubectl get svc $APP_NAME -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    if [ -z "$SERVICE_URL" ]; then
        SERVICE_URL=$(kubectl get svc $APP_NAME -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    fi
    
    print_success "Deployment verified successfully"
    print_status "Application URL: http://$SERVICE_URL"
}

# Function to show next steps
show_next_steps() {
    echo ""
    print_status "=== DEPLOYMENT COMPLETED ==="
    echo ""
    print_status "Next steps:"
    echo "1. Access your application: http://$SERVICE_URL"
    echo "2. Run incident simulations: ./scripts/incident-simulator.sh"
    echo "3. Access Grafana dashboard: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
    echo "4. Monitor your application: kubectl get pods -l app.kubernetes.io/name=$APP_NAME"
    echo ""
    print_status "Useful commands:"
    echo "- Check application logs: kubectl logs -l app.kubernetes.io/name=$APP_NAME"
    echo "- Check resource usage: kubectl top pods -l app.kubernetes.io/name=$APP_NAME"
    echo "- Scale application: kubectl scale deployment $APP_NAME --replicas=3"
    echo "- Restart application: kubectl rollout restart deployment $APP_NAME"
    echo ""
    print_warning "Remember to clean up resources when done:"
    echo "- helm uninstall $APP_NAME"
    echo "- helm uninstall prometheus -n monitoring"
    echo "- cd terraform && terraform destroy"
    echo ""
}

# Main function
main() {
    print_status "Starting SRE Demo deployment..."
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Get AWS account ID
    get_aws_account_id
    
    # Create ECR repository
    create_ecr_repository
    
    # Deploy infrastructure
    deploy_infrastructure
    
    # Build and push application
    build_and_push_app
    
    # Deploy application
    deploy_application
    
    # Setup monitoring
    setup_monitoring
    
    # Verify deployment
    verify_deployment
    
    # Show next steps
    show_next_steps
    
    print_success "SRE Demo deployment completed successfully!"
}

# Run main function
main "$@" 