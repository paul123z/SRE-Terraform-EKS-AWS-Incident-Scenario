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
AWS_CMD=$(command -v aws || echo "/usr/local/bin/aws")
KUBECTL_CMD=$(command -v kubectl || echo "/usr/local/bin/kubectl")

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
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed"
        exit 1
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null && ! /usr/local/bin/kubectl version --client &> /dev/null; then
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
    AWS_CMD=$(command -v aws || echo "/usr/local/bin/aws")
    if ! $AWS_CMD sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured"
        exit 1
    fi
    
    # Note: Node.js will be installed in Docker container, so we don't need it locally
    print_success "All prerequisites are satisfied"
}

# Function to get AWS account ID
get_aws_account_id() {
    # Use full path if aws not in PATH
    AWS_CMD=$(command -v aws || echo "/usr/local/bin/aws")
    AWS_ACCOUNT_ID=$($AWS_CMD sts get-caller-identity --query Account --output text)
    print_status "AWS Account ID: $AWS_ACCOUNT_ID"
}

# Function to create ECR repository
create_ecr_repository() {
    print_status "Creating ECR repository..."
    
    if ! $AWS_CMD ecr describe-repositories --repository-names $ECR_REPOSITORY --region $AWS_REGION &> /dev/null; then
        $AWS_CMD ecr create-repository --repository-name $ECR_REPOSITORY --region $AWS_REGION
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
    $AWS_CMD eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
    
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
    $AWS_CMD ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
    
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
    
    # Install EBS CSI Driver for persistent volume support
    print_status "Installing EBS CSI Driver..."
    
    # Remove existing EBS CSI Driver if installed with kubectl
    $KUBECTL_CMD delete -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.28" || true
    
    # Add AWS EBS CSI Driver Helm repository
    helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
    helm repo update
    
    # Install EBS CSI Driver using Helm
    helm upgrade --install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
        --namespace kube-system \
        --wait \
        --timeout 5m
    
    # Wait for EBS CSI Driver to be ready
    print_status "Waiting for EBS CSI Driver to be ready..."
    $KUBECTL_CMD wait --for=condition=ready pod -l app=ebs-csi-controller -n kube-system --timeout=300s
    
    # Get the node group name dynamically
    print_status "Adding EBS CSI Driver permissions to node group..."
    NODE_GROUP_NAME=$($AWS_CMD eks list-nodegroups --cluster-name $CLUSTER_NAME --region $AWS_REGION --query 'nodegroups[0]' --output text)
    NODE_GROUP_ROLE=$($AWS_CMD eks describe-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $NODE_GROUP_NAME --region $AWS_REGION --query 'nodegroup.nodeRole' --output text | cut -d'/' -f2)
    
    # Attach EBS CSI Driver policy to node group role
    $AWS_CMD iam attach-role-policy --role-name $NODE_GROUP_ROLE --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy
    
    print_status "EBS CSI Driver setup completed"
    
    # Install Metrics Server for resource monitoring
    print_status "Installing Metrics Server..."
    $KUBECTL_CMD apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    $KUBECTL_CMD wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=300s
    print_success "Metrics Server installed"
    
    # Add Prometheus Helm repository
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    
    # Install Prometheus with Grafana
    print_status "Installing Prometheus and Grafana..."
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        -f monitoring/prometheus-values.yaml \
        --namespace monitoring \
        --create-namespace \
        --wait \
        --timeout 15m
    
    print_success "Monitoring setup completed"
}

# Function to verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Check if pods are running
    $KUBECTL_CMD wait --for=condition=ready pod -l app.kubernetes.io/name=$APP_NAME -n $NAMESPACE --timeout=300s
    
    # Check service
    $KUBECTL_CMD get svc $APP_NAME -n $NAMESPACE
    
    # Check HPA
    $KUBECTL_CMD get hpa -n $NAMESPACE
    
    # Get service URL
    SERVICE_URL=$($KUBECTL_CMD get svc $APP_NAME -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    if [ -z "$SERVICE_URL" ]; then
        SERVICE_URL=$($KUBECTL_CMD get svc $APP_NAME -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
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