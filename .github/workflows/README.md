# 🔄 GitHub Actions Workflows

This directory contains GitHub Actions workflows for the SRE Demo project. All workflows are configured for **manual execution only** to provide full control over when deployments happen.

## 📋 Available Workflows

### **1. `deploy.yml` - Full Infrastructure & Application Deployment**
**Purpose**: Complete end-to-end deployment of the entire SRE demo environment.

**Trigger**: Manual (`workflow_dispatch`)

**What it does**:
- ✅ **Testing**: Runs Node.js application tests
- ✅ **Infrastructure**: Deploys EKS cluster, VPC, networking via Terraform
- ✅ **Building**: Builds Docker image from `app/` directory
- ✅ **Pushing**: Pushes image to ECR with `latest` tag
- ✅ **Deploying**: Deploys application using Helm charts
- ✅ **Monitoring**: Installs Prometheus, Grafana, Metrics Server
- ✅ **Verification**: Checks deployment status and health

**Use case**: Initial setup or complete redeployment of the entire environment.

**Estimated runtime**: 15-20 minutes

**Required secrets**:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

---

### **2. `build-push-deploy-app.yml` - Build, Push & Deploy Application**
**Purpose**: Build a new Docker image and deploy the application (infrastructure must already exist).

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

### **3. `deploy-app-only.yml` - Application Deployment Only**
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

## 🚀 How to Use

### **Running Workflows**

1. **Go to your GitHub repository**
2. **Navigate to Actions tab**
3. **Select the desired workflow**
4. **Click "Run workflow"**
5. **Wait for completion**

### **Workflow Selection Guide**

| Scenario | Use This Workflow | When |
|----------|------------------|------|
| **First time setup** | `deploy.yml` | Initial deployment |
| **Code changes** | `build-push-deploy-app.yml` | After updating application code |
| **Redeploy same image** | `deploy-app-only.yml` | Configuration changes only |
| **Complete rebuild** | `deploy.yml` | Full environment refresh |

---

## 🔧 Configuration

### **Environment Variables**

All workflows use these environment variables:
```yaml
AWS_REGION: eu-central-1
CLUSTER_NAME: sre-incident-demo-cluster
APP_NAME: sre-demo-app
ECR_REPOSITORY: sre-demo-app
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

---

## 📊 Workflow Outputs

### **Successful Deployment Output**

After a successful workflow run, you'll see:

```
✅ Application deployed successfully!

🐳 Docker Images:
- Latest: 123456789012.dkr.ecr.eu-central-1.amazonaws.com/sre-demo-app:latest
- Tagged: 123456789012.dkr.ecr.eu-central-1.amazonaws.com/sre-demo-app:abc123

🌐 Service URL:
http://a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6-1234567890.eu-central-1.elb.amazonaws.com

📊 Pod status:
NAME                            READY   STATUS    RESTARTS   AGE
sre-demo-app-678c44fb5-n5fs7    1/1     Running   0          2m

🔍 Application health:
{"status":"healthy","timestamp":"2025-08-05T22:00:00.000Z"}

📈 Resource usage:
NAME                            CPU(cores)   MEMORY(bytes)   
sre-demo-app-678c44fb5-n5fs7    1m           19Mi
```

### **Next Steps After Deployment**

1. **Test the application**: Visit the service URL
2. **Run incident demo**: Use `./scripts/incident-demo.sh`
3. **Access Grafana**: `kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80`
4. **Monitor logs**: `kubectl logs -l app.kubernetes.io/name=sre-demo-app`

---

## 🔍 Troubleshooting

### **Common Issues**

#### **Workflow Fails with "Credentials could not be loaded"**
- **Solution**: Check that `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` secrets are configured
- **Verify**: Go to Settings → Secrets and variables → Actions

#### **Workflow Fails with "No such file or directory"**
- **Solution**: Ensure all required files exist in the repository
- **Check**: `app/Dockerfile`, `helm/sre-demo-app/`, `terraform/`

#### **Workflow Fails with "Cluster not found"**
- **Solution**: Run `deploy.yml` first to create infrastructure
- **Alternative**: Use `deploy-app-only.yml` if cluster exists

#### **Workflow Fails with "Image pull failed"**
- **Solution**: Use `build-push-deploy-app.yml` to build and push a new image
- **Check**: Ensure ECR repository exists and is accessible

### **Debugging Commands**

If you need to debug locally:

```bash
# Check cluster status
aws eks describe-cluster --name sre-incident-demo-cluster --region eu-central-1

# Check ECR repository
aws ecr describe-repositories --repository-names sre-demo-app --region eu-central-1

# Check application status
kubectl get pods -l app.kubernetes.io/name=sre-demo-app

# Check service status
kubectl get svc sre-demo-app
```

---

## 🔄 Workflow Comparison

| Feature | `deploy.yml` | `build-push-deploy-app.yml` | `deploy-app-only.yml` |
|---------|--------------|------------------------------|----------------------|
| **Infrastructure** | ✅ Creates | ❌ Requires existing | ❌ Requires existing |
| **Building** | ✅ Builds image | ✅ Builds image | ❌ Uses existing |
| **Pushing** | ✅ Pushes to ECR | ✅ Pushes to ECR | ❌ No pushing |
| **Deploying** | ✅ Deploys app | ✅ Deploys app | ✅ Deploys app |
| **Monitoring** | ✅ Installs | ❌ Requires existing | ❌ Requires existing |
| **Runtime** | 15-20 min | 5-10 min | 3-5 min |
| **Use case** | Initial setup | Code updates | Redeploy |

---

## 🎯 Best Practices

### **When to Use Each Workflow**

1. **`deploy.yml`**: 
   - First time setup
   - Complete environment refresh
   - After infrastructure changes

2. **`build-push-deploy-app.yml`**:
   - After code changes
   - When you want a new image
   - Regular deployments

3. **`deploy-app-only.yml`**:
   - Configuration changes only
   - Quick redeployments
   - Testing deployment process

### **Workflow Optimization**

- **Use manual triggers** to control when deployments happen
- **Monitor workflow logs** for any issues
- **Verify deployments** after each workflow run
- **Clean up resources** when done using `./scripts/teardown.sh`

---

## 📚 Related Documentation

- **Main README**: `../README.md` - Complete project documentation
- **Scripts README**: `../scripts/README.md` - Local script documentation
- **Deployment Summary**: `../DEPLOYMENT_SUMMARY.md` - Quick reference
- **Incident Walkthrough**: `../INCIDENT_DETECTION_RESOLUTION.md` - Demo guide

---

## 🤝 Contributing

When adding new workflows:

1. **Use manual triggers** (`workflow_dispatch`) for control
2. **Include proper error handling** and verification steps
3. **Document the workflow** in this README
4. **Test thoroughly** before committing
5. **Follow naming conventions** for consistency

---

*Last updated: August 2025* 