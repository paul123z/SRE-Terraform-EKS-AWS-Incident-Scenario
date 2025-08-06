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

# Function to build Lambda function (if needed)
build_lambda() {
    print_status "Building Lambda function for AI incident analysis..."
    
    # Check if Lambda ZIP file already exists
    if [ -f "lambda/incident-analyzer.zip" ]; then
        print_status "Lambda ZIP file already exists, skipping build"
        return 0
    fi
    
    # Check if Lambda directory exists
    if [ ! -d "lambda" ]; then
        print_error "Lambda directory not found: lambda/"
        print_error "Please ensure the lambda directory exists with incident-analyzer.py"
        exit 1
    fi
    
    # Check if Lambda Python file exists
    if [ ! -f "lambda/incident-analyzer.py" ]; then
        print_error "Lambda Python file not found: lambda/incident-analyzer.py"
        print_error "Please ensure the lambda directory contains incident-analyzer.py"
        exit 1
    fi
    
    # Check if build script exists
    if [ ! -f "scripts/build-lambda.sh" ]; then
        print_error "Lambda build script not found: scripts/build-lambda.sh"
        print_error "Please ensure the build-lambda.sh script exists"
        exit 1
    fi
    
    # Build Lambda function
    ./scripts/build-lambda.sh
    
    # Verify ZIP file was created
    if [ ! -f "lambda/incident-analyzer.zip" ]; then
        print_error "Lambda build failed - ZIP file not created"
        exit 1
    fi
    
    print_success "Lambda function built successfully"
}

# Function to deploy infrastructure
deploy_infrastructure() {
    print_status "Deploying infrastructure with Terraform..."
    
    # Build Lambda function first (as per YouTube guide)
    build_lambda
    
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
    
    # Check if app directory and Dockerfile exist
    if [ ! -d "app" ]; then
        print_error "App directory not found: app/"
        print_error "Please ensure the app directory exists"
        exit 1
    fi
    
    if [ ! -f "app/Dockerfile" ]; then
        print_error "Dockerfile not found: app/Dockerfile"
        print_error "Please ensure the app directory contains a Dockerfile"
        exit 1
    fi
    
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
    
    # Check if Helm chart directory exists
    if [ ! -d "helm/sre-demo-app" ]; then
        print_error "Helm chart directory not found: helm/sre-demo-app/"
        print_error "Please ensure the helm/sre-demo-app directory exists"
        exit 1
    fi
    
    cd helm/sre-demo-app
    
    # Install the application
    print_status "Installing application with Helm..."
    helm upgrade --install $APP_NAME . \
        --set image.repository=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY \
        --set image.tag=latest \
        --namespace $NAMESPACE \
        --create-namespace \
        --wait \
        --timeout 5m
    
    cd ../..
    
    # Verify service was created
    print_status "Verifying service creation..."
    if ! kubectl get svc $APP_NAME -n $NAMESPACE &> /dev/null; then
        print_warning "Service was not created by Helm. Creating manually..."
        
        # Create service manually
        kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: $APP_NAME
  namespace: $NAMESPACE
  labels:
    app.kubernetes.io/name: $APP_NAME
    app.kubernetes.io/instance: $APP_NAME
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 3000
      protocol: TCP
      name: http
  selector:
    app.kubernetes.io/name: $APP_NAME
    app.kubernetes.io/instance: $APP_NAME
EOF
        
        print_success "Service created manually"
    else
        print_success "Service created successfully by Helm"
    fi
    
    print_success "Application deployed successfully"
}

# Function to setup Kubernetes Dashboard
setup_dashboard() {
    print_status "Setting up Kubernetes Dashboard..."
    
    # Install the dashboard
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
    
    # Create admin service account
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dashboard-admin
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dashboard-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: dashboard-admin
  namespace: kubernetes-dashboard
EOF
    
    # Wait for dashboard pods to be ready
    print_status "Waiting for Kubernetes Dashboard to be ready..."
    if kubectl wait --for=condition=ready pod -l k8s-app=kubernetes-dashboard -n kubernetes-dashboard --timeout=30s 2>/dev/null; then
        print_success "Kubernetes Dashboard is ready"
    else
        # Check if pods are already running
        if kubectl get pods -l k8s-app=kubernetes-dashboard -n kubernetes-dashboard --no-headers | grep -q "Running"; then
            print_success "Kubernetes Dashboard is already running"
        else
            print_warning "Dashboard pods may still be starting up. You can check status with: kubectl get pods -n kubernetes-dashboard"
        fi
    fi
    
    print_success "Kubernetes Dashboard setup completed"
}

# Function to setup monitoring
setup_monitoring() {
    print_status "Setting up monitoring..."
    
    # Check if monitoring configuration exists
    if [ ! -f "monitoring/prometheus-values.yaml" ]; then
        print_error "Monitoring configuration not found: monitoring/prometheus-values.yaml"
        print_error "Please ensure the monitoring directory contains the prometheus-values.yaml file"
        exit 1
    fi
    
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
    print_status "Waiting for pods to be ready..."
    $KUBECTL_CMD wait --for=condition=ready pod -l app.kubernetes.io/name=$APP_NAME -n $NAMESPACE --timeout=300s
    
    # Check service
    print_status "Checking service status..."
    $KUBECTL_CMD get svc $APP_NAME -n $NAMESPACE
    
    # Check HPA
    print_status "Checking Horizontal Pod Autoscaler..."
    $KUBECTL_CMD get hpa -n $NAMESPACE
    
    # Wait for load balancer to be provisioned
    print_status "Waiting for load balancer to be provisioned..."
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        SERVICE_URL=$($KUBECTL_CMD get svc $APP_NAME -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
        if [ -n "$SERVICE_URL" ]; then
            break
        fi
        
        SERVICE_URL=$($KUBECTL_CMD get svc $APP_NAME -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
        if [ -n "$SERVICE_URL" ]; then
            break
        fi
        
        print_status "Load balancer still provisioning... (attempt $((attempt + 1))/$max_attempts)"
        sleep 10
        attempt=$((attempt + 1))
    done
    
    if [ -z "$SERVICE_URL" ]; then
        print_warning "Load balancer URL not available yet. It may take a few more minutes."
        print_status "You can check the status with: kubectl get svc $APP_NAME -n $NAMESPACE"
    else
        print_success "Load balancer URL obtained: $SERVICE_URL"
    fi
    
    print_success "Deployment verified successfully"
    if [ -n "$SERVICE_URL" ]; then
        print_status "Application URL: http://$SERVICE_URL"
    fi
}

# Function to validate demo scripts
validate_demo_scripts() {
    print_status "Validating demo scripts..."
    
    local missing_scripts=()
    
    # Check for required demo scripts
    if [ ! -f "scripts/incident-demo.sh" ]; then
        missing_scripts+=("scripts/incident-demo.sh")
    fi
    
    if [ ! -f "scripts/analyze-incident.sh" ]; then
        missing_scripts+=("scripts/analyze-incident.sh")
    fi
    
    if [ ! -f "scripts/teardown.sh" ]; then
        missing_scripts+=("scripts/teardown.sh")
    fi
    
    if [ ! -f "scripts/teardown-verify.sh" ]; then
        missing_scripts+=("scripts/teardown-verify.sh")
    fi
    
    if [ ${#missing_scripts[@]} -gt 0 ]; then
        print_warning "Some demo scripts are missing:"
        for script in "${missing_scripts[@]}"; do
            echo "  - $script"
        done
        print_warning "These scripts are used in the YouTube presentation guide"
        print_warning "The deployment will continue, but some demo features may not work"
    else
        print_success "All demo scripts are available"
    fi
}

# Function to validate Helm chart
validate_helm_chart() {
    print_status "Validating Helm chart..."
    
    local missing_templates=()
    
    # Check for required Helm templates
    if [ ! -f "helm/sre-demo-app/templates/deployment.yaml" ]; then
        missing_templates+=("helm/sre-demo-app/templates/deployment.yaml")
    fi
    
    if [ ! -f "helm/sre-demo-app/templates/service.yaml" ]; then
        missing_templates+=("helm/sre-demo-app/templates/service.yaml")
    fi
    
    if [ ! -f "helm/sre-demo-app/templates/serviceaccount.yaml" ]; then
        missing_templates+=("helm/sre-demo-app/templates/serviceaccount.yaml")
    fi
    
    if [ ! -f "helm/sre-demo-app/templates/hpa.yaml" ]; then
        missing_templates+=("helm/sre-demo-app/templates/hpa.yaml")
    fi
    
    if [ ! -f "helm/sre-demo-app/values.yaml" ]; then
        missing_templates+=("helm/sre-demo-app/values.yaml")
    fi
    
    if [ ! -f "helm/sre-demo-app/Chart.yaml" ]; then
        missing_templates+=("helm/sre-demo-app/Chart.yaml")
    fi
    
    if [ ${#missing_templates[@]} -gt 0 ]; then
        print_error "Helm chart is incomplete. Missing templates:"
        for template in "${missing_templates[@]}"; do
            echo "  - $template"
        done
        print_error "Please ensure all Helm chart templates are present"
        exit 1
    else
        print_success "Helm chart is complete"
    fi
}

# Function to show next steps
show_next_steps() {
    echo ""
    print_status "=== DEPLOYMENT COMPLETED ==="
    echo ""
    print_status "Next steps:"
    echo "1. Access your application: http://$SERVICE_URL"
    echo "2. Run incident simulations: ./scripts/incident-demo.sh"
    echo "3. Access Grafana dashboard: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
    echo "4. Access Kubernetes Dashboard: ./scripts/access-dashboard.sh (automated setup and access)"
    echo "5. Or manually: kubectl proxy + ./scripts/get-dashboard-token.sh"
    echo "6. Monitor your application: kubectl get pods -l app.kubernetes.io/name=$APP_NAME"
    echo ""
    print_status "Useful commands:"
    echo "- Check application logs: kubectl logs -l app.kubernetes.io/name=$APP_NAME"
    echo "- Check resource usage: kubectl top pods -l app.kubernetes.io/name=$APP_NAME"
    echo "- Scale application: kubectl scale deployment $APP_NAME --replicas=3"
    echo "- Restart application: kubectl rollout restart deployment $APP_NAME"
    echo ""
    print_status "AI Incident Analysis (as per YouTube guide):"
    echo "- Run enhanced incident demo: ./scripts/incident-demo.sh"
    echo "- Analyze incidents with AI: ./scripts/analyze-incident.sh -i <incident-id>"
    echo ""
    print_warning "Remember to clean up resources when done:"
    echo "- Automated cleanup: ./scripts/teardown.sh"
    echo "- Verify cleanup: ./scripts/teardown-verify.sh"
    echo "- Manual cleanup: helm uninstall $APP_NAME && helm uninstall prometheus -n monitoring && cd terraform && terraform destroy"
    echo ""
}

# Main function
main() {
    print_status "Starting SRE Demo deployment..."
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Validate demo scripts (as per YouTube guide)
    validate_demo_scripts
    
    # Validate Helm chart
    validate_helm_chart
    
    # Get AWS account ID
    get_aws_account_id
    
    # Create ECR repository
    create_ecr_repository
    
    # Deploy infrastructure
    deploy_infrastructure
    
    # Setup Kubernetes Dashboard (before app deployment)
    setup_dashboard
    
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