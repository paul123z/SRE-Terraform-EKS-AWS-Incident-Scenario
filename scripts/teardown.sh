#!/bin/bash

# SRE Demo Teardown Script
# This script safely removes all infrastructure and resources

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
AWS_CMD=$(command -v aws || echo "/usr/local/bin/aws")
KUBECTL_CMD=$(command -v kubectl || echo "/usr/local/bin/kubectl")
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

# Function to check if cluster exists
check_cluster_exists() {
    if $AWS_CMD eks describe-cluster --region $AWS_REGION --name $CLUSTER_NAME &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to check if kubectl is configured
check_kubectl_config() {
if $KUBECTL_CMD cluster-info &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to remove Helm releases
remove_helm_releases() {
    print_status "Removing Helm releases..."
    
    # Remove application
    if helm list -n $NAMESPACE | grep -q $APP_NAME; then
        helm uninstall $APP_NAME -n $NAMESPACE
        print_success "Application uninstalled"
    else
        print_status "Application not found"
    fi
    
    # Remove monitoring
    if helm list -n monitoring | grep -q prometheus; then
        helm uninstall prometheus -n monitoring
        print_success "Monitoring uninstalled"
    else
        print_status "Monitoring not found"
    fi
}

# Function to clean up ECR
cleanup_ecr() {
    print_status "Cleaning up ECR repository..."
    
    if $AWS_CMD ecr describe-repositories --repository-names $ECR_REPOSITORY --region $AWS_REGION &> /dev/null; then
        # Delete all images
        $AWS_CMD ecr batch-delete-image \
            --repository-name $ECR_REPOSITORY \
            --image-ids imageTag=latest \
            --region $AWS_REGION || true
        
        # Delete repository
        $AWS_CMD ecr delete-repository \
            --repository-name $ECR_REPOSITORY \
            --force \
            --region $AWS_REGION
        
        print_success "ECR repository deleted"
    else
        print_status "ECR repository not found"
    fi
}

# Function to clean up EBS CSI Driver
cleanup_ebs_csi_driver() {
    print_status "Cleaning up EBS CSI Driver..."
    
    if check_kubectl_config; then
        # Remove EBS CSI Driver
        helm uninstall aws-ebs-csi-driver -n kube-system || true
        
        # Remove IAM policy from node group role
        NODE_GROUP_NAME=$($AWS_CMD eks list-nodegroups --cluster-name $CLUSTER_NAME --region $AWS_REGION --query 'nodegroups[0]' --output text 2>/dev/null || echo "")
        if [ -n "$NODE_GROUP_NAME" ]; then
            NODE_GROUP_ROLE=$($AWS_CMD eks describe-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $NODE_GROUP_NAME --region $AWS_REGION --query 'nodegroup.nodeRole' --output text | cut -d'/' -f2)
            $AWS_CMD iam detach-role-policy --role-name $NODE_GROUP_ROLE --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy || true
            print_success "EBS CSI Driver cleaned up"
        else
            print_status "Node group not found, skipping EBS CSI Driver cleanup"
        fi
    else
        print_status "kubectl not configured, skipping EBS CSI Driver cleanup"
    fi
}

# Function to clean up S3 bucket
cleanup_s3_bucket() {
    print_status "Cleaning up S3 bucket..."
    
    cd terraform
    
    # Get bucket name from Terraform output
    BUCKET_NAME=$(terraform output -raw incident_logs_bucket 2>/dev/null || echo "")
    
    if [ -n "$BUCKET_NAME" ]; then
        print_status "Found S3 bucket: $BUCKET_NAME"
        
        # Remove all object versions (including delete markers)
        print_status "Removing all object versions..."
        $AWS_CMD s3api list-object-versions \
            --bucket "$BUCKET_NAME" \
            --region "$AWS_REGION" \
            --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
            --output json > /tmp/versions.json 2>/dev/null || true
        
        if [ -s /tmp/versions.json ] && [ "$(jq -r '.Objects | length' /tmp/versions.json)" -gt 0 ]; then
            $AWS_CMD s3api delete-objects \
                --bucket "$BUCKET_NAME" \
                --delete file:///tmp/versions.json \
                --region "$AWS_REGION" || true
            print_success "Object versions deleted"
        fi
        
        # Remove all delete markers
        print_status "Removing delete markers..."
        $AWS_CMD s3api list-object-versions \
            --bucket "$BUCKET_NAME" \
            --region "$AWS_REGION" \
            --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' \
            --output json > /tmp/delete-markers.json 2>/dev/null || true
        
        if [ -s /tmp/delete-markers.json ] && [ "$(jq -r '.Objects | length' /tmp/delete-markers.json)" -gt 0 ]; then
            $AWS_CMD s3api delete-objects \
                --bucket "$BUCKET_NAME" \
                --delete file:///tmp/delete-markers.json \
                --region "$AWS_REGION" || true
            print_success "Delete markers removed"
        fi
        
        # Remove all objects (non-versioned)
        print_status "Removing all objects..."
        $AWS_CMD s3 rm "s3://$BUCKET_NAME" --recursive --region "$AWS_REGION" || true
        
        print_success "S3 bucket contents cleaned up"
    else
        print_status "S3 bucket not found in Terraform output"
    fi
    
    # Clean up temporary files
    rm -f /tmp/versions.json /tmp/delete-markers.json
    
    cd ..
}

# Function to destroy infrastructure
destroy_infrastructure() {
    print_status "Destroying infrastructure with Terraform..."
    
    cd terraform
    
    # Check if state file exists
    if [ ! -f "terraform.tfstate" ]; then
        print_warning "No Terraform state file found. Infrastructure may already be destroyed."
        cd ..
        return
    fi
    
    # Destroy infrastructure
    terraform destroy -auto-approve
    
    cd ..
    
    print_success "Infrastructure destroyed successfully"
}

# Function to clean up local files
cleanup_local_files() {
    print_status "Cleaning up local files..."
    
    # Remove Terraform state files
    if [ -f "terraform/terraform.tfstate" ]; then
        rm terraform/terraform.tfstate*
        print_success "Terraform state files removed"
    fi
    
    # Remove Terraform lock file
    if [ -f "terraform/.terraform.lock.hcl" ]; then
        rm terraform/.terraform.lock.hcl
        print_success "Terraform lock file removed"
    fi
    
    # Remove .terraform directory
    if [ -d "terraform/.terraform" ]; then
        rm -rf terraform/.terraform
        print_success "Terraform cache removed"
    fi
}

# Function to show cleanup summary
show_cleanup_summary() {
    echo ""
    print_status "=== CLEANUP COMPLETED ==="
    echo ""
    print_status "The following resources have been removed:"
    echo "✅ EKS Cluster: $CLUSTER_NAME"
    echo "✅ VPC and networking resources"
    echo "✅ IAM roles and policies"
    echo "✅ Application deployment"
    echo "✅ Monitoring stack (Prometheus/Grafana)"
    echo "✅ EBS CSI Driver and IAM policies"
    echo "✅ ECR repository and images"
    echo "✅ S3 bucket and contents"
    echo "✅ Local Terraform state files"
    echo ""
    print_warning "Note: Some AWS resources may take a few minutes to fully delete"
    echo ""
    print_status "To verify cleanup, you can:"
    echo "- Check EKS clusters: $AWS_CMD eks list-clusters --region $AWS_REGION"
    echo "- Check ECR repositories: $AWS_CMD ecr describe-repositories --region $AWS_REGION"
    echo "- Check VPCs: $AWS_CMD ec2 describe-vpcs --region $AWS_REGION"
    echo ""
}

# Main function
main() {
    print_status "Starting SRE Demo teardown..."
    echo ""
    
    # Check if cluster exists
    if ! check_cluster_exists; then
        print_warning "EKS cluster not found. Some resources may already be cleaned up."
    fi
    
    # Update kubeconfig if cluster exists
    if check_cluster_exists; then
        print_status "Updating kubeconfig..."
        $AWS_CMD eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
        
        # Remove Helm releases if kubectl is configured
        if check_kubectl_config; then
            remove_helm_releases
        else
            print_warning "kubectl not configured. Skipping Helm cleanup."
        fi
    fi
    
    # Clean up ECR
    cleanup_ecr
    
    # Clean up EBS CSI Driver
    cleanup_ebs_csi_driver
    
    # Clean up S3 bucket
    cleanup_s3_bucket
    
    # Destroy infrastructure
    destroy_infrastructure
    
    # Clean up local files
    cleanup_local_files
    
    # Show summary
    show_cleanup_summary
    
    print_success "SRE Demo teardown completed successfully!"
}

# Run main function
main "$@" 