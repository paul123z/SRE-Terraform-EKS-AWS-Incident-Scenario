#!/bin/bash

# Comprehensive Setup Validation Script
# This script validates all components before deployment

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
AWS_REGION="eu-central-1"
CLUSTER_NAME="sre-incident-demo-cluster"
ECR_REPOSITORY="sre-demo-app"
APP_NAME="sre-demo-app"
NAMESPACE="default"

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    local missing_tools=()
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null && ! /usr/local/bin/aws --version &> /dev/null; then
        missing_tools+=("AWS CLI")
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("Terraform")
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null && ! /usr/local/bin/kubectl version --client &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    # Check Helm
    if ! command -v helm &> /dev/null; then
        missing_tools+=("Helm")
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        missing_tools+=("Docker")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Missing required tools:"
        for tool in "${missing_tools[@]}"; do
            echo "  - $tool"
        done
        return 1
    else
        print_success "All prerequisites are satisfied"
        return 0
    fi
}

# Function to check AWS configuration
check_aws_config() {
    print_status "Checking AWS configuration..."
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured"
        return 1
    fi
    
    # Get AWS account ID
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    print_success "AWS Account ID: $AWS_ACCOUNT_ID"
    
    # Check if ECR repository exists
    if aws ecr describe-repositories --repository-names $ECR_REPOSITORY --region $AWS_REGION &> /dev/null; then
        print_success "ECR repository exists"
    else
        print_warning "ECR repository does not exist (will be created during deployment)"
    fi
    
    return 0
}

# Function to check project structure
check_project_structure() {
    print_status "Checking project structure..."
    
    local missing_files=()
    
    # Check required directories
    if [ ! -d "terraform" ]; then
        missing_files+=("terraform/")
    fi
    
    if [ ! -d "app" ]; then
        missing_files+=("app/")
    fi
    
    if [ ! -d "helm/sre-demo-app" ]; then
        missing_files+=("helm/sre-demo-app/")
    fi
    
    if [ ! -d "lambda" ]; then
        missing_files+=("lambda/")
    fi
    
    if [ ! -d "monitoring" ]; then
        missing_files+=("monitoring/")
    fi
    
    if [ ! -d "scripts" ]; then
        missing_files+=("scripts/")
    fi
    
    # Check required files
    if [ ! -f "app/Dockerfile" ]; then
        missing_files+=("app/Dockerfile")
    fi
    
    if [ ! -f "lambda/incident-analyzer.py" ]; then
        missing_files+=("lambda/incident-analyzer.py")
    fi
    
    if [ ! -f "monitoring/prometheus-values.yaml" ]; then
        missing_files+=("monitoring/prometheus-values.yaml")
    fi
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        print_error "Missing required files/directories:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        return 1
    else
        print_success "Project structure is complete"
        return 0
    fi
}

# Function to check Helm chart
check_helm_chart() {
    print_status "Checking Helm chart..."
    
    local missing_templates=()
    
    # Check required Helm templates
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
        return 1
    else
        print_success "Helm chart is complete"
        return 0
    fi
}

# Function to check demo scripts
check_demo_scripts() {
    print_status "Checking demo scripts..."
    
    local missing_scripts=()
    
    # Check for required demo scripts
    if [ ! -f "scripts/incident-demo.sh" ]; then
        missing_scripts+=("scripts/incident-demo.sh")
    fi
    
    if [ ! -f "scripts/analyze-incident-simple.sh" ]; then
        missing_scripts+=("scripts/analyze-incident-simple.sh")
    fi
    
    if [ ! -f "scripts/teardown.sh" ]; then
        missing_scripts+=("scripts/teardown.sh")
    fi
    
    if [ ! -f "scripts/teardown-verify.sh" ]; then
        missing_scripts+=("scripts/teardown-verify.sh")
    fi
    
    if [ ! -f "scripts/build-lambda.sh" ]; then
        missing_scripts+=("scripts/build-lambda.sh")
    fi
    
    if [ ! -f "scripts/get-dashboard-token.sh" ]; then
        missing_scripts+=("scripts/get-dashboard-token.sh")
    fi
    
    if [ ! -f "scripts/access-dashboard.sh" ]; then
        missing_scripts+=("scripts/access-dashboard.sh")
    fi
    
    if [ ${#missing_scripts[@]} -gt 0 ]; then
        print_warning "Some demo scripts are missing:"
        for script in "${missing_scripts[@]}"; do
            echo "  - $script"
        done
        print_warning "These scripts are used in the YouTube presentation guide"
        return 1
    else
        print_success "All demo scripts are available"
        return 0
    fi
}

# Function to check Terraform configuration
check_terraform_config() {
    print_status "Checking Terraform configuration..."
    
    cd terraform
    
    # Check if Terraform is initialized
    if [ ! -d ".terraform" ]; then
        print_warning "Terraform not initialized (will be done during deployment)"
    else
        print_success "Terraform is initialized"
    fi
    
    # Check if state exists
    if [ -f "terraform.tfstate" ]; then
        print_warning "Terraform state exists - infrastructure may already be deployed"
    else
        print_success "No existing Terraform state found"
    fi
    
    cd ..
    
    return 0
}

# Function to check Kubernetes cluster (if available)
check_kubernetes_cluster() {
    print_status "Checking Kubernetes cluster..."
    
    # Check if kubectl is configured
    if ! kubectl cluster-info &> /dev/null; then
        print_warning "Kubectl not configured for any cluster"
        return 0
    fi
    
    # Check if our cluster is accessible
    if kubectl get nodes &> /dev/null; then
        print_success "Kubernetes cluster is accessible"
        
        # Check if our cluster is the right one
        if kubectl config current-context | grep -q "$CLUSTER_NAME"; then
            print_success "Correct cluster context is active"
        else
            print_warning "Cluster context may not be correct. Expected: $CLUSTER_NAME"
        fi
    else
        print_warning "Cannot access Kubernetes cluster"
    fi
    
    return 0
}

# Function to validate Lambda function
validate_lambda_function() {
    print_status "Validating Lambda function..."
    
    # Check if Lambda ZIP exists
    if [ -f "lambda/incident-analyzer.zip" ]; then
        print_success "Lambda ZIP file exists"
        echo "  Size: $(du -h lambda/incident-analyzer.zip | cut -f1)"
    else
        print_warning "Lambda ZIP file not found (will be built during deployment)"
    fi
    
    # Check if Python file exists
    if [ -f "lambda/incident-analyzer.py" ]; then
        print_success "Lambda Python file exists"
    else
        print_error "Lambda Python file not found"
        return 1
    fi
    
    # Check if requirements.txt exists
    if [ -f "lambda/requirements.txt" ]; then
        print_success "Lambda requirements.txt exists"
    else
        print_warning "Lambda requirements.txt not found (will be created during build)"
    fi
    
    return 0
}

# Function to show summary
show_summary() {
    echo ""
    print_status "=== VALIDATION SUMMARY ==="
    echo ""
    
    if [ $1 -eq 0 ]; then
        print_success "✅ All validations passed! Your setup is ready for deployment."
        echo ""
        print_status "Next steps:"
        echo "1. Run: ./scripts/deploy.sh (automated deployment)"
        echo "2. Or follow the manual steps in YOUTUBE_PRESENTATION_GUIDE.md"
        echo ""
        print_status "For YouTube recording:"
        echo "- Use the automated script for reliability"
        echo "- Or use manual steps for educational purposes"
    else
        print_error "❌ Some validations failed. Please fix the issues above before deploying."
        echo ""
        print_status "Common fixes:"
        echo "1. Install missing tools (see error messages above)"
        echo "2. Configure AWS credentials: aws configure"
        echo "3. Check project structure and missing files"
        echo "4. Run this validation script again after fixes"
    fi
    echo ""
}

# Main function
main() {
    print_status "Starting comprehensive setup validation..."
    echo ""
    
    local exit_code=0
    
    # Run all validations
    check_prerequisites || exit_code=1
    echo ""
    
    check_aws_config || exit_code=1
    echo ""
    
    check_project_structure || exit_code=1
    echo ""
    
    check_helm_chart || exit_code=1
    echo ""
    
    check_demo_scripts || exit_code=1
    echo ""
    
    check_terraform_config || exit_code=1
    echo ""
    
    check_kubernetes_cluster || exit_code=1
    echo ""
    
    validate_lambda_function || exit_code=1
    echo ""
    
    # Show summary
    show_summary $exit_code
    
    exit $exit_code
}

# Run main function
main "$@" 