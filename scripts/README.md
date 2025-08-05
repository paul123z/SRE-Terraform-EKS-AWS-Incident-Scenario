# 📁 Scripts Directory

This directory contains automation scripts for the SRE Demo project. Each script serves a specific purpose in the deployment, management, and testing of the infrastructure and application.

## 🚀 **Deployment Scripts**

### **`deploy.sh`** - Full Infrastructure & Application Deployment
**Purpose**: Complete end-to-end deployment of the entire SRE demo environment.

**What it does**:
- ✅ Checks prerequisites (AWS CLI, Terraform, kubectl, Helm, Docker)
- ✅ Creates ECR repository
- ✅ Deploys infrastructure (EKS cluster, VPC, networking)
- ✅ Builds and pushes Docker image to ECR
- ✅ Deploys application using Helm
- ✅ Installs EBS CSI Driver and Metrics Server
- ✅ Sets up monitoring (Prometheus/Grafana)
- ✅ Verifies deployment and shows next steps

**Usage**:
```bash
./scripts/deploy.sh
```

**When to use**: Initial setup or complete redeployment of the entire environment.

---

### **`deploy-app-only.sh`** - Application Deployment Only
**Purpose**: Deploy only the application using an existing Docker image from ECR.

**What it does**:
- ✅ Checks prerequisites
- ✅ Updates kubeconfig
- ✅ Deploys application using Helm
- ✅ Verifies deployment
- ✅ Shows application URL

**Usage**:
```bash
./scripts/deploy-app-only.sh
```

**When to use**: When infrastructure is already deployed and you want to deploy/update only the application.

---

### **`build-and-push.sh`** - Build and Push Docker Image
**Purpose**: Build a new Docker image and push it to ECR.

**What it does**:
- ✅ Checks prerequisites
- ✅ Builds Docker image from `app/` directory
- ✅ Logs in to ECR
- ✅ Tags and pushes image to ECR
- ✅ Optionally redeploys application
- ✅ Verifies deployment

**Usage**:
```bash
./scripts/build-and-push.sh
```

**When to use**: When you've made changes to the application code and need to update the Docker image.

**Alternative**: Use GitHub Actions workflow `build-push-deploy-app.yml` for automated build, push, and deploy.

---

## 🧹 **Cleanup Scripts**

### **`teardown.sh`** - Complete Environment Cleanup
**Purpose**: Safely remove all infrastructure and resources.

**What it does**:
- ✅ Removes Helm releases (application and monitoring)
- ✅ Cleans up ECR repository and images
- ✅ Removes EBS CSI Driver and IAM policies
- ✅ Destroys Terraform infrastructure
- ✅ Cleans up local files
- ✅ Shows cleanup summary

**Usage**:
```bash
./scripts/teardown.sh
```

**When to use**: When you're done with the demo and want to clean up all resources to avoid costs.

---

### **`teardown-verify.sh`** - Teardown Verification
**Purpose**: Verify that all AWS resources have been properly cleaned up.

**What it does**:
- ✅ Checks EKS clusters (should be deleted)
- ✅ Checks ECR repositories (should be deleted)
- ✅ Checks VPCs and networking (should be deleted)
- ✅ Checks Load Balancers (should be deleted)
- ✅ Checks Security Groups (should be deleted)
- ✅ Checks EC2 instances (should be deleted)
- ✅ Checks IAM roles (warns if still exist)
- ✅ Checks EBS volumes (warns if still exist)
- ✅ Checks local Terraform files (should be deleted)
- ✅ Provides detailed summary with next steps

**Usage**:
```bash
./scripts/teardown-verify.sh
```

**When to use**: After running `teardown.sh` to verify everything is cleaned up properly.

---

## 🚨 **Testing & Simulation Scripts**

### **`incident-simulator.sh`** - Interactive Incident Simulation
**Purpose**: Interactive tool for simulating various incident scenarios.

**What it does**:
- ✅ Provides menu-driven interface
- ✅ Simulates health check failures
- ✅ Simulates slow response times
- ✅ Simulates memory leaks
- ✅ Simulates CPU stress
- ✅ Shows pod status and metrics
- ✅ Allows scaling and restarting applications

**Usage**:
```bash
./scripts/incident-simulator.sh
```

**Available options**:
1. Check application health
2. Simulate health check failure
3. Simulate slow response
4. Simulate memory leak
5. Simulate CPU stress
6. Reset all simulations
7. Show pod status
8. Show metrics
9. Show HPA status
10. Show service status
11. Scale application
12. Restart application
13. Show incident timeline
14. Exit

**When to use**: For testing incident response procedures and demonstrating SRE practices.

---

### **`incident-demo.sh`** - Guided Incident Demo
**Purpose**: Walkthrough of a complete incident detection and resolution scenario.

**What it does**:
- ✅ Checks prerequisites and node count
- ✅ Shows initial healthy state
- ✅ Simulates memory leak incident
- ✅ Demonstrates detection methods
- ✅ Shows diagnosis procedures
- ✅ Performs resolution steps
- ✅ Verifies recovery
- ✅ Provides summary of SRE practices demonstrated

**Usage**:
```bash
./scripts/incident-demo.sh
```

**When to use**: For presentations, training, or demonstrating the complete SRE incident response process.

---

## 🔧 **Utility Scripts**

### **`get-dashboard-token.sh`** - Kubernetes Dashboard Token Generator
**Purpose**: Generate authentication tokens for the Kubernetes Dashboard.

**What it does**:
- ✅ Generates token for dashboard-admin service account
- ✅ Displays token for easy copying
- ✅ Shows usage instructions

**Usage**:
```bash
./scripts/get-dashboard-token.sh
```

**When to use**: When you need to access the Kubernetes Dashboard and the token has expired.

---

## 📋 **Script Dependencies**

### **Prerequisites for All Scripts**:
- **AWS CLI**: Configured with appropriate credentials
- **kubectl**: Installed and configured
- **Helm**: Installed (v3.x)
- **Docker**: Installed and running
- **Terraform**: Installed (for deploy.sh and teardown.sh)

### **AWS Permissions Required**:
- EKS cluster management
- ECR repository access
- IAM role management
- EC2 instance management
- VPC and networking

---

## 🎯 **Common Use Cases**

### **Initial Setup**:
```bash
# Deploy everything from scratch
./scripts/deploy.sh
```

### **Application Updates**:
```bash
# Build and push new image
./scripts/build-and-push.sh

# Or deploy existing image
./scripts/deploy-app-only.sh
```

### **Testing Incidents**:
```bash
# Interactive simulation
./scripts/incident-simulator.sh

# Or guided demo
./scripts/incident-demo.sh
```

### **Cleanup**:
```bash
# Remove everything
./scripts/teardown.sh
```

---

## 🔍 **Troubleshooting**

### **Common Issues**:

1. **"Too many pods" error**:
   - Scale up node group: `aws eks update-nodegroup-config --cluster-name sre-incident-demo-cluster --nodegroup-name main-20250805185921253500000011 --scaling-config minSize=2,maxSize=3,desiredSize=2 --region eu-central-1`

2. **Metrics server not available**:
   - Install metrics server: `kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml`

3. **ECR login issues**:
   - Check AWS credentials: `aws sts get-caller-identity`
   - Verify region configuration

4. **Helm deployment failures**:
   - Check pod events: `kubectl get events --sort-by='.lastTimestamp'`
   - Verify resource limits and requests

### **Log Locations**:
- **Application logs**: `kubectl logs -l app.kubernetes.io/name=sre-demo-app`
- **Pod events**: `kubectl get events --sort-by='.lastTimestamp'`
- **Deployment status**: `kubectl describe deployment sre-demo-app`

---

## 📚 **Additional Resources**

- **Main README**: `../README.md` - Complete project documentation
- **Deployment Summary**: `../DEPLOYMENT_SUMMARY.md` - Quick reference
- **Incident Walkthrough**: `../INCIDENT_DETECTION_RESOLUTION.md` - Detailed incident response guide

---

## 🤝 **Contributing**

When adding new scripts:
1. Follow the existing naming convention
2. Include proper error handling
3. Add colored output for better UX
4. Document the script in this README
5. Test thoroughly before committing

---

*Last updated: August 2025* 