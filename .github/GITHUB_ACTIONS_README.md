# 🔄 GitHub Actions Workflows

This repository contains comprehensive GitHub Actions workflows for deploying, managing, and tearing down SRE demo infrastructure on AWS EKS. All workflows are configured for **manual execution only** and use **S3-based Terraform state management** for infrastructure deployment and teardown.

## 📋 Available Workflows

### **1. `deploy.yml` - Infrastructure Deployment**
**Purpose**: Deploys complete EKS infrastructure using Terraform with S3 state management.

**Trigger**: Manual (`workflow_dispatch`)

**What it does**:
- ✅ **S3 Setup**: Creates S3 bucket for Terraform state
- ✅ **State Management**: Downloads existing state if available
- ✅ **Infrastructure**: Deploys EKS cluster, VPC, and monitoring stack
- ✅ **State Upload**: Stores Terraform state in S3 for future use
- ✅ **Verification**: Makes scripts executable and shows deployment summary

**Use case**: Initial infrastructure setup or infrastructure updates.

**Estimated runtime**: 15-20 minutes

**Required secrets**:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

---

### **2. `teardown.yml` - Infrastructure Teardown**
**Purpose**: Safely removes all infrastructure using Terraform state from S3.

**Trigger**: Manual (`workflow_dispatch`)

**What it does**:
- ✅ **State Retrieval**: Downloads Terraform state from S3
- ✅ **Terraform Destroy**: Uses `terraform destroy` for proper cleanup
- ✅ **Fallback**: Falls back to script-based teardown if no state found
- ✅ **State Cleanup**: Removes state from S3 after successful teardown
- ✅ **Complete Bucket Cleanup**: Deletes the entire S3 bucket when all resources are successfully removed
- ✅ **Verification**: Shows teardown summary

**Use case**: Complete infrastructure cleanup before redeploying or for cost savings.

**Estimated runtime**: 10-15 minutes

**Required secrets**:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

---

### **3. `teardown-verify.yml` - Teardown Verification**
**Purpose**: Verifies complete cleanup of all AWS resources and S3 state.

**Trigger**: Manual (`workflow_dispatch`)

**What it does**:
- ✅ **Resource Checks**: Verifies no EKS clusters, ECR repos, VPCs, or Load Balancers remain
- ✅ **State Verification**: Ensures no Terraform state remains in S3
- ✅ **Bucket Cleanup**: Confirms S3 state bucket is also cleaned up
- ✅ **Validation**: Fails if any resources remain

**Use case**: Verify complete cleanup after teardown operations.

**Estimated runtime**: 2-3 minutes

**Required secrets**:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

---

### **4. `incident-demo.yml` - SRE Incident Demo**
**Purpose**: Runs SRE incident scenario demonstrations.

**Trigger**: Manual (`workflow_dispatch`)

**What it does**:
- ✅ **Tool Installation**: Installs kubectl and Helm with pinned versions
- ✅ **Demo Execution**: Runs incident demo script
- ✅ **Status Display**: Shows pod status, resource usage, and HPA behavior

**Use case**: Demonstrate SRE incident scenarios and response procedures.

**Estimated runtime**: 5-10 minutes

**Required secrets**:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

**Prerequisites**: EKS cluster must be running.

---

### **5. `build-push-deploy-app.yml` - Application Deployment**
**Purpose**: Builds, pushes, and deploys the application to existing infrastructure.

**Trigger**: Manual (`workflow_dispatch`)

**What it does**:
- ✅ **Building**: Builds Docker image from `app/` directory
- ✅ **Tagging**: Tags with both `latest` and commit SHA
- ✅ **Pushing**: Pushes images to ECR
- ✅ **Deploying**: Deploys application using Helm
- ✅ **Verification**: Checks deployment status and health
- ✅ **Reporting**: Shows service URLs and next steps

**Use case**: When you've updated application code and want to deploy the changes.

**Estimated runtime**: 5-10 minutes

**Required secrets**:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

**Prerequisites**: EKS cluster and infrastructure must already be deployed.

---

### **6. `deploy-app-only.yml` - Application Deployment Only**
**Purpose**: Deploy an existing Docker image from ECR (no building).

**Trigger**: Manual (`workflow_dispatch`)

**What it does**:
- ✅ **Deploying**: Deploys existing image using Helm
- ✅ **Verification**: Checks deployment status
- ✅ **Reporting**: Shows service URL and pod status

**Use case**: When you want to redeploy the same image (e.g., after configuration changes).

**Estimated runtime**: 3-5 minutes

**Required secrets**:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

**Prerequisites**: EKS cluster and Docker image must already exist in ECR.

---

### **7. `analyze-s3-logs.yml` - S3 Log Analysis**
**Purpose**: Analyzes S3 access logs and CloudTrail data.

**Trigger**: Manual (`workflow_dispatch`)

**What it does**:
- ✅ **S3 Download**: Retrieves log files from S3 bucket
- ✅ **Data Processing**: Analyzes access patterns and security events
- ✅ **Reporting**: Generates insights and recommendations

**Use case**: Analyze incident logs stored in S3 after running incident demos.

**Estimated runtime**: 30-60 seconds

**Required secrets**:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

**Prerequisites**: S3 bucket with incident logs.

---

## 🔧 S3 Terraform State Management

### **How It Works**

- **`deploy.yml`** creates an S3 bucket and stores Terraform state there
- **`teardown.yml`** retrieves the state from S3 and uses it for proper teardown
- **`teardown-verify.yml`** ensures no state remains in S3
- All workflows use the same S3 bucket: `sre-incident-demo-terraform-state`

### **Robust State Management**

**Critical Safety Feature**: State management steps use `if: always()` to ensure they execute even if the main Terraform operations fail.

- **Deploy Workflow**: S3 state upload always happens, even if `terraform apply` fails
- **Teardown Workflow**: S3 state cleanup always happens, even if `terraform destroy` fails
- **Complete Cleanup**: S3 bucket is completely deleted when teardown succeeds
- **Failure Handling**: Dedicated failure handling steps provide clear guidance on next actions

This prevents:
- ❌ Orphaned resources without state tracking
- ❌ Inability to clean up partial deployments
- ❌ Lost state files that prevent proper teardown

### **State Flow**

```
Local Development:
deploy.sh → .tfstate (local) → teardown.sh (local)

GitHub Actions:
deploy.yml → .tfstate (S3) → teardown.yml (S3) → teardown-verify.yml (S3)
```

### **Benefits of S3 State Management**

- ✅ **Centralized State**: State is stored securely in S3
- ✅ **Team Collaboration**: Multiple team members can access the same state
- ✅ **State Persistence**: State survives local machine changes
- ✅ **Automatic Cleanup**: State is automatically removed after teardown
- ✅ **Complete Bucket Cleanup**: S3 bucket is completely deleted after successful teardown
- ✅ **Versioning**: S3 bucket has versioning enabled for rollback capability

---

## 🚀 How to Use

### **Complete Infrastructure Deployment (Recommended)**

1. **Deploy Infrastructure**: Run `deploy.yml` workflow
2. **Deploy Application**: Run `build-push-deploy-app.yml` workflow
3. **Run Demo**: Use `incident-demo.yml` workflow
4. **Cleanup**: Run `teardown.yml` workflow
5. **Verify**: Run `teardown-verify.yml` workflow

### **Manual Execution**

All workflows are manually triggered using the GitHub Actions UI:

1. **Go to Actions tab**
2. **Select desired workflow**
3. **Click "Run workflow"**
4. **Select branch and click "Run workflow"**

### **Workflow Selection Guide**

| Scenario | Use This Workflow | When |
|----------|------------------|------|
| **First time setup** | `deploy.yml` | Infrastructure + Application |
| **Code changes** | `build-push-deploy-app.yml` | After updating application code |
| **Redeploy same image** | `deploy-app-only.yml` | Configuration changes only |
| **Run incident demo** | `incident-demo.yml` | Demonstrate SRE scenarios |
| **Complete cleanup** | `teardown.yml` | Remove all infrastructure |
| **Verify cleanup** | `teardown-verify.yml` | Confirm complete removal |

---

## 🔧 Configuration

### **Environment Variables**

All workflows use these environment variables:
```yaml
AWS_REGION: eu-central-1
CLUSTER_NAME: sre-incident-demo-cluster
APP_NAME: sre-demo-app
ECR_REPOSITORY: sre-demo-app
TF_STATE_BUCKET: sre-incident-demo-terraform-state
TF_STATE_KEY: terraform.tfstate
TF_STATE_REGION: eu-central-1
```

### **Required GitHub Secrets**

You must configure these secrets in your repository:

1. **Go to Settings → Secrets and variables → Actions**
2. **Add the following secrets**:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | AWS access key | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key | `wJalrXUtnFEMI...` |

### **AWS Permissions Required**

Your AWS credentials need these permissions:
- **EKS**: Create, delete, and manage clusters
- **ECR**: Create repositories and push images
- **EC2**: Manage instances, VPC, and networking
- **IAM**: Create and manage roles and policies
- **ELB**: Create and manage load balancers
- **S3**: Create and manage buckets for Terraform state

---

## 🎯 Future-Proof Features

### **Ubuntu Version Pinning**
All workflows use `ubuntu-22.04` instead of `ubuntu-latest` for stability.

### **GitHub Actions Pinning**
- `actions/checkout@v4.1.0`
- `actions/setup-python@v4.7.0`
- `actions/setup-node@v4.1.0`
- `aws-actions/configure-aws-credentials@v4.0.2`
- `aws-actions/amazon-ecr-login@v2.0.0`
- `azure/setup-helm@v3.13.3`
- `hashicorp/setup-terraform@v3.7.5`

### **System Package Pinning**
- **Python**: `3.11.9`
- **Node.js**: `18.19.0`
- **AWS CLI v2**: `2.15.42`
- **kubectl**: `1.28.8`
- **Helm**: `3.13.3`
- **Terraform**: `1.7.5`
- **Docker**: `5:24.0.7-1~ubuntu.22.04~jammy`

### **Additional Tools (Pinned)**
- **jq**: `1.6-1ubuntu1`
- **curl**: `7.68.0-1ubuntu2.18`
- **wget**: `1.20.3-1ubuntu2`
- **unzip**: `6.0-25ubuntu1.1`
- **git**: `1:2.34.1-1ubuntu1.10`

---

## 📊 Workflow Outputs

### **Successful Deployment Output**

After a successful `deploy.yml` workflow run, you'll see:

```
✅ Infrastructure deployment completed successfully!

🌐 Cluster: sre-incident-demo-cluster
🏗️  Region: eu-central-1
📦 App: sre-demo-app
🪣 Terraform State: s3://sre-incident-demo-terraform-state/terraform.tfstate

🔍 Next steps:
1. Run build-push-deploy-app workflow to deploy the application
2. Run incident demo: ./scripts/incident-demo.sh
3. Access Grafana: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
4. Check app status: kubectl get pods -l app.kubernetes.io/name=sre-demo-app

🗑️  To clean up: Run the teardown workflow
```

### **Successful Teardown Output**

After a successful `teardown.yml` workflow run, you'll see:

```
✅ Teardown completed!

🗑️  Resources removed via Terraform:
- EKS Cluster: sre-incident-demo-cluster
- ECR Repository: sre-demo-app
- Application: sre-demo-app
- Monitoring stack
- All associated AWS resources
- Terraform state cleaned from S3

⚠️  Note: Some resources may take a few minutes to fully terminate
```

---

## 🔍 Troubleshooting

### **Common Issues**

- **State not found**: Ensure `deploy.yml` ran successfully first
- **Permission errors**: Check AWS credentials and IAM permissions
- **Resource conflicts**: Use `teardown.yml` to clean up before redeploying
- **S3 access issues**: Verify S3 bucket permissions and bucket existence

### **Debug Steps**

1. **Check workflow logs** for specific error messages
2. **Verify AWS credentials** are properly configured
3. **Ensure S3 bucket exists** and is accessible
4. **Check Terraform state file** in S3
5. **Verify IAM permissions** for all required AWS services

### **Workflow Dependencies**

```
deploy.yml → build-push-deploy-app.yml → incident-demo.yml
     ↓
teardown.yml → teardown-verify.yml
```

---

## 📚 Best Practices

1. **Always run teardown before redeploying** to avoid resource conflicts
2. **Use teardown-verify** to ensure complete cleanup
3. **Monitor workflow logs** for any errors or warnings
4. **Keep workflows updated** with latest security patches
5. **Test in feature branches** before merging to main
6. **Use S3 state management** for team collaboration and state persistence

---

## 🔒 Security Considerations

- All workflows use least-privilege IAM roles
- S3 state bucket has encryption enabled
- State files are automatically cleaned up after teardown
- No sensitive data is logged in workflow outputs
- All dependencies are pinned to specific versions

---

## 📞 Support

For issues or questions:

1. **Check workflow logs** for error details
2. **Verify AWS credentials** and permissions
3. **Ensure all prerequisites** are met
4. **Review this documentation** for common solutions
5. **Check the main README** for additional information

---

**Note**: These workflows are designed to be production-ready and future-proof. All dependencies are pinned to specific versions to ensure consistent behavior across different environments and time periods. The S3-based Terraform state management provides centralized state storage and enables team collaboration while maintaining security and automatic cleanup.
