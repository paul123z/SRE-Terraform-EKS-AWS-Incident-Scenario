# GitHub Actions Workflows for SRE Demo Infrastructure

This repository contains comprehensive GitHub Actions workflows for deploying, managing, and tearing down SRE demo infrastructure on AWS EKS. All workflows are designed to be **future-proof** with specific version pinning and S3-based Terraform state management.

## 🚀 Workflow Overview

### Core Infrastructure Workflows

1. **`deploy.yml`** - Deploys complete infrastructure using Terraform
2. **`teardown.yml`** - Safely removes infrastructure using Terraform state
3. **`teardown-verify.yml`** - Verifies complete cleanup of all resources
4. **`incident-demo.yml`** - Runs SRE incident scenario demonstrations

### Application Deployment Workflows

5. **`build-push-deploy-app.yml`** - Builds, pushes, and deploys the application
6. **`deploy-app-only.yml`** - Deploys only the application (requires existing infrastructure)
7. **`analyze-s3-logs.yml`** - Analyzes S3 access logs and CloudTrail data

## 🔧 S3 Terraform State Management

### How It Works

- **`deploy.yml`** creates an S3 bucket and stores Terraform state there
- **`teardown.yml`** retrieves the state from S3 and uses it for proper teardown
- **`teardown-verify.yml`** ensures no state remains in S3
- All workflows use the same S3 bucket: `sre-incident-demo-terraform-state`

### State Flow

```
Local Development:
deploy.sh → .tfstate (local) → teardown.sh (local)

GitHub Actions:
deploy.yml → .tfstate (S3) → teardown.yml (S3) → teardown-verify.yml (S3)
```

## 📋 Workflow Details

### 1. Deploy Infrastructure (`deploy.yml`)

**Purpose**: Deploys complete EKS infrastructure using Terraform

**Features**:
- Creates S3 bucket for Terraform state
- Downloads existing state if available
- Deploys EKS cluster, VPC, and monitoring stack
- Uploads final state to S3

**Manual Trigger**: `workflow_dispatch`

**Environment Variables**:
```yaml
AWS_REGION: eu-central-1
CLUSTER_NAME: sre-incident-demo-cluster
TF_STATE_BUCKET: sre-incident-demo-terraform-state
TF_STATE_KEY: terraform.tfstate
```

### 2. Teardown Infrastructure (`teardown.yml`)

**Purpose**: Safely removes all infrastructure using Terraform state

**Features**:
- Retrieves Terraform state from S3
- Uses `terraform destroy` for proper cleanup
- Falls back to script-based teardown if no state found
- Cleans up state from S3 after successful teardown

**Manual Trigger**: `workflow_dispatch`

### 3. Teardown Verification (`teardown-verify.yml`)

**Purpose**: Verifies complete cleanup of all AWS resources

**Features**:
- Checks for remaining EKS clusters, ECR repos, VPCs, Load Balancers
- Verifies no Terraform state remains in S3
- Ensures S3 state bucket is also cleaned up
- Fails if any resources remain

**Manual Trigger**: `workflow_dispatch`

### 4. Incident Demo (`incident-demo.yml`)

**Purpose**: Runs SRE incident scenario demonstrations

**Features**:
- Installs kubectl and Helm with pinned versions
- Runs incident demo script
- Shows pod status, resource usage, and HPA behavior

**Manual Trigger**: `workflow_dispatch`

### 5. Build & Deploy App (`build-push-deploy-app.yml`)

**Purpose**: Builds, pushes, and deploys the application

**Features**:
- Builds Docker image with unique tags
- Pushes to ECR
- Deploys to EKS using Helm
- Includes monitoring stack setup

**Manual Trigger**: `workflow_dispatch`

### 6. Deploy App Only (`deploy-app-only.yml`)

**Purpose**: Deploys only the application (requires existing infrastructure)

**Features**:
- Assumes EKS cluster is already running
- Builds and pushes Docker image
- Deploys application with Helm

**Manual Trigger**: `workflow_dispatch`

### 7. Analyze S3 Logs (`analyze-s3-logs.yml`)

**Purpose**: Analyzes S3 access logs and CloudTrail data

**Features**:
- Downloads and processes S3 access logs
- Analyzes CloudTrail events
- Generates security insights

**Manual Trigger**: `workflow_dispatch`

## 🎯 Future-Proof Features

### Ubuntu Version Pinning
All workflows use `ubuntu-22.04` instead of `ubuntu-latest` for stability.

### GitHub Actions Pinning
- `actions/checkout@v4.1.0`
- `actions/setup-python@v4.7.0`
- `actions/setup-node@v4.1.0`
- `aws-actions/configure-aws-credentials@v4.0.2`
- `aws-actions/amazon-ecr-login@v2.0.0`
- `azure/setup-helm@v3.13.3`
- `hashicorp/setup-terraform@v3.7.5`

### System Package Pinning
- **Python**: `3.11.9`
- **Node.js**: `18.19.0`
- **AWS CLI v2**: `2.15.42`
- **kubectl**: `1.28.8`
- **Helm**: `3.13.3`
- **Terraform**: `1.7.5`
- **Docker**: `5:24.0.7-1~ubuntu.22.04~jammy`

### Additional Tools (Pinned)
- **jq**: `1.6-1ubuntu1`
- **curl**: `7.68.0-1ubuntu2.18`
- **wget**: `1.20.3-1ubuntu2`
- **unzip**: `6.0-25ubuntu1.1`
- **git**: `1:2.34.1-1ubuntu1.10`

## 🚀 Usage Instructions

### Prerequisites
1. AWS credentials configured as GitHub secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

2. AWS region: `eu-central-1`

### Deployment Flow
1. **Deploy Infrastructure**: Run `deploy.yml` workflow
2. **Deploy Application**: Run `build-push-deploy-app.yml` workflow
3. **Run Demo**: Use `incident-demo.yml` workflow
4. **Cleanup**: Run `teardown.yml` workflow
5. **Verify**: Run `teardown-verify.yml` workflow

### Manual Execution
All workflows are manually triggered using the GitHub Actions UI:
1. Go to Actions tab
2. Select desired workflow
3. Click "Run workflow"
4. Select branch and click "Run workflow"

## 🔍 Troubleshooting

### Common Issues
- **State not found**: Ensure `deploy.yml` ran successfully first
- **Permission errors**: Check AWS credentials and IAM permissions
- **Resource conflicts**: Use `teardown.yml` to clean up before redeploying

### Debug Steps
1. Check workflow logs for specific error messages
2. Verify AWS credentials are properly configured
3. Ensure S3 bucket exists and is accessible
4. Check Terraform state file in S3

## 🏗️ Architecture

### Infrastructure Components
- **EKS Cluster**: Kubernetes cluster for application deployment
- **VPC**: Network infrastructure with public/private subnets
- **ECR Repository**: Container image storage
- **Monitoring Stack**: Prometheus, Grafana, and alerting
- **Load Balancer**: Application access point

### State Management
- **S3 Backend**: Centralized Terraform state storage
- **State Versioning**: Enabled for rollback capability
- **Encryption**: Server-side encryption for state files
- **Access Control**: IAM-based permissions

## 📚 Best Practices

1. **Always run teardown before redeploying** to avoid resource conflicts
2. **Use teardown-verify** to ensure complete cleanup
3. **Monitor workflow logs** for any errors or warnings
4. **Keep workflows updated** with latest security patches
5. **Test in feature branches** before merging to main

## 🔒 Security Considerations

- All workflows use least-privilege IAM roles
- S3 state bucket has encryption enabled
- State files are automatically cleaned up after teardown
- No sensitive data is logged in workflow outputs

## 📞 Support

For issues or questions:
1. Check workflow logs for error details
2. Verify AWS credentials and permissions
3. Ensure all prerequisites are met
4. Review this documentation for common solutions

---

**Note**: These workflows are designed to be production-ready and future-proof. All dependencies are pinned to specific versions to ensure consistent behavior across different environments and time periods.
