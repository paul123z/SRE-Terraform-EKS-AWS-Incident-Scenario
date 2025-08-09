#!/bin/bash

# Teardown Verification Script
# This script verifies that all AWS resources have been properly cleaned up

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
VPC_NAME="sre-incident-demo-vpc"
AWS_CMD=$(command -v aws || echo "/usr/local/bin/aws")

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

# Function to check AWS credentials
check_aws_credentials() {
    print_status "Checking AWS credentials..."
    if ! $AWS_CMD sts get-caller-identity > /dev/null 2>&1; then
        print_error "AWS credentials not configured"
        exit 1
    fi
    print_success "AWS credentials are valid"
}

# Function to check EKS clusters
check_eks_clusters() {
    print_status "Checking EKS clusters..."
    
    CLUSTERS=$($AWS_CMD eks list-clusters --region $AWS_REGION --query 'clusters' --output text 2>/dev/null || echo "")
    
    if [ -z "$CLUSTERS" ]; then
        print_success "No EKS clusters found"
        return 0
    fi
    
    if echo "$CLUSTERS" | grep -q "$CLUSTER_NAME"; then
        print_error "EKS cluster '$CLUSTER_NAME' still exists"
        return 1
    else
        print_success "Project EKS cluster not found"
        return 0
    fi
}

# Function to check ECR repositories
check_ecr_repositories() {
    print_status "Checking ECR repositories..."
    
    REPOS=$($AWS_CMD ecr describe-repositories --region $AWS_REGION --query 'repositories[].repositoryName' --output text 2>/dev/null || echo "")
    
    if [ -z "$REPOS" ]; then
        print_success "No ECR repositories found"
        return 0
    fi
    
    if echo "$REPOS" | grep -q "$ECR_REPOSITORY"; then
        print_error "ECR repository '$ECR_REPOSITORY' still exists"
        return 1
    else
        print_success "Project ECR repository not found"
        return 0
    fi
}

# Function to check VPCs
check_vpcs() {
    print_status "Checking VPCs..."
    
    VPC_IDS=$($AWS_CMD ec2 describe-vpcs --region $AWS_REGION --filters "Name=tag:Name,Values=$VPC_NAME" --query 'Vpcs[].VpcId' --output text 2>/dev/null || echo "")
    
    if [ -z "$VPC_IDS" ]; then
        print_success "Project VPC not found"
        return 0
    else
        print_error "Project VPC still exists: $VPC_IDS"
        return 1
    fi
}

# Function to check Load Balancers
check_load_balancers() {
    print_status "Checking Load Balancers..."
    
    LBS=$($AWS_CMD elbv2 describe-load-balancers --region $AWS_REGION --query 'LoadBalancers[?contains(LoadBalancerName, `sre-incident-demo`)].LoadBalancerName' --output text 2>/dev/null || echo "")
    
    if [ -z "$LBS" ]; then
        print_success "No project Load Balancers found"
        return 0
    else
        print_error "Project Load Balancers still exist: $LBS"
        return 1
    fi
}

# Function to check IAM roles
check_iam_roles() {
    print_status "Checking IAM roles..."
    
    ROLES=$($AWS_CMD iam list-roles --query 'Roles[?contains(RoleName, `sre-incident-demo`) || contains(RoleName, `main-eks-node-group`)].RoleName' --output text 2>/dev/null || echo "")
    
    if [ -z "$ROLES" ]; then
        print_success "No project IAM roles found"
        return 0
    else
        print_warning "Project IAM roles still exist: $ROLES"
        print_status "Note: Some IAM roles may take time to delete or may be shared"
        return 0
    fi
}

# Function to check Security Groups
check_security_groups() {
    print_status "Checking Security Groups..."
    
    SGS=$($AWS_CMD ec2 describe-security-groups --region $AWS_REGION --filters "Name=group-name,Values=*sre-incident-demo*" --query 'SecurityGroups[].GroupName' --output text 2>/dev/null || echo "")
    
    if [ -z "$SGS" ]; then
        print_success "No project Security Groups found"
        return 0
    else
        print_error "Project Security Groups still exist: $SGS"
        return 1
    fi
}

# Function to check EC2 instances
check_ec2_instances() {
    print_status "Checking EC2 instances..."
    
    INSTANCES=$($AWS_CMD ec2 describe-instances --region $AWS_REGION --filters "Name=tag:Name,Values=*sre-incident-demo*" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].InstanceId' --output text 2>/dev/null || echo "")
    
    if [ -z "$INSTANCES" ]; then
        print_success "No project EC2 instances found"
        return 0
    else
        print_error "Project EC2 instances still running: $INSTANCES"
        return 1
    fi
}

# Function to check EBS volumes
check_ebs_volumes() {
    print_status "Checking EBS volumes..."
    
    VOLUMES=$($AWS_CMD ec2 describe-volumes --region $AWS_REGION --filters "Name=tag:Name,Values=*sre-incident-demo*" "Name=status,Values=available" --query 'Volumes[].VolumeId' --output text 2>/dev/null || echo "")
    
    if [ -z "$VOLUMES" ]; then
        print_success "No project EBS volumes found"
        return 0
    else
        print_warning "Project EBS volumes still exist: $VOLUMES"
        print_status "Note: EBS volumes may take time to delete"
        return 0
    fi
}

# Function to check local files
check_local_files() {
    print_status "Checking local files..."
    
    local missing_files=0
    
    # Check Terraform state files
    if [ -f "../terraform/terraform.tfstate" ]; then
        print_warning "Terraform state file still exists"
        missing_files=$((missing_files + 1))
    else
        print_success "Terraform state file removed"
    fi
    
    # Check Terraform lock file
    if [ -f "../terraform/.terraform.lock.hcl" ]; then
        print_warning "Terraform lock file still exists"
        missing_files=$((missing_files + 1))
    else
        print_success "Terraform lock file removed"
    fi
    
    # Check .terraform directory
    if [ -d "../terraform/.terraform" ]; then
        print_warning "Terraform cache directory still exists"
        missing_files=$((missing_files + 1))
    else
        print_success "Terraform cache directory removed"
    fi
    
    if [ $missing_files -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Function to show verification summary
show_verification_summary() {
    echo ""
    print_status "=== TEARDOWN VERIFICATION SUMMARY ==="
    echo ""
    
    if [ $TOTAL_ERRORS -eq 0 ] && [ $TOTAL_WARNINGS -eq 0 ]; then
        print_success "🎉 ALL RESOURCES SUCCESSFULLY CLEANED UP!"
        echo ""
        print_status "Your AWS account is clean and ready for fresh deployment."
        echo ""
        print_status "Next time you want to deploy:"
        echo "1. Run: ./scripts/deploy.sh"
        echo "2. Or use GitHub Actions: Build, Push & Deploy Application"
        echo ""
    elif [ $TOTAL_ERRORS -eq 0 ]; then
        print_warning "⚠️  MOSTLY CLEANED UP (with warnings)"
        echo ""
        print_status "Most resources are cleaned up, but some items may need manual attention."
        echo ""
    else
        print_error "❌ CLEANUP INCOMPLETE"
        echo ""
        print_status "Some resources still exist and may need manual cleanup."
        echo ""
        print_status "You can manually clean up remaining resources or wait for automatic deletion."
        echo ""
    fi
    
    echo "📊 Summary:"
    echo "- Errors: $TOTAL_ERRORS"
    echo "- Warnings: $TOTAL_WARNINGS"
    echo "- Success: $TOTAL_SUCCESS"
    echo ""
}

# Main function
main() {
    print_status "Starting teardown verification..."
    echo ""
    
    # Initialize counters
    TOTAL_ERRORS=0
    TOTAL_WARNINGS=0
    TOTAL_SUCCESS=0
    
    # Check AWS credentials
    check_aws_credentials
    TOTAL_SUCCESS=$((TOTAL_SUCCESS + 1))
    
    echo ""
    print_status "Verifying AWS resource cleanup..."
    echo ""
    
    # Check EKS clusters
    if check_eks_clusters; then
        TOTAL_SUCCESS=$((TOTAL_SUCCESS + 1))
    else
        TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
    fi
    
    # Check ECR repositories
    if check_ecr_repositories; then
        TOTAL_SUCCESS=$((TOTAL_SUCCESS + 1))
    else
        TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
    fi
    
    # Check VPCs
    if check_vpcs; then
        TOTAL_SUCCESS=$((TOTAL_SUCCESS + 1))
    else
        TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
    fi
    
    # Check Load Balancers
    if check_load_balancers; then
        TOTAL_SUCCESS=$((TOTAL_SUCCESS + 1))
    else
        TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
    fi
    
    # Check Security Groups
    if check_security_groups; then
        TOTAL_SUCCESS=$((TOTAL_SUCCESS + 1))
    else
        TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
    fi
    
    # Check EC2 instances
    if check_ec2_instances; then
        TOTAL_SUCCESS=$((TOTAL_SUCCESS + 1))
    else
        TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
    fi
    
    # Check IAM roles
    if check_iam_roles; then
        TOTAL_SUCCESS=$((TOTAL_SUCCESS + 1))
    else
        TOTAL_WARNINGS=$((TOTAL_WARNINGS + 1))
    fi
    
    # Check EBS volumes
    if check_ebs_volumes; then
        TOTAL_SUCCESS=$((TOTAL_SUCCESS + 1))
    else
        TOTAL_WARNINGS=$((TOTAL_WARNINGS + 1))
    fi
    
    echo ""
    print_status "Checking local files..."
    echo ""
    
    # Check local files
    if check_local_files; then
        TOTAL_SUCCESS=$((TOTAL_SUCCESS + 1))
    else
        TOTAL_WARNINGS=$((TOTAL_WARNINGS + 1))
    fi
    
    # Show summary
    show_verification_summary
    
    # Exit with appropriate code
    if [ $TOTAL_ERRORS -eq 0 ]; then
        print_success "Teardown verification completed successfully!"
        exit 0
    else
        print_error "Teardown verification found issues that need attention."
        exit 1
    fi
}

# Run main function
main "$@" 