# 🔄 Deployment Scripts Comparison

## Overview
This project provides two different deployment approaches: a comprehensive manual script and an automated CI/CD pipeline.

## 📋 `scripts/deploy.sh` - Complete Manual Deployment

### **Purpose**
Full end-to-end deployment from scratch, including infrastructure provisioning and monitoring setup.

### **What it does:**
- ✅ **Infrastructure Provisioning**: Terraform apply for VPC, EKS, IAM
- ✅ **ECR Repository**: Creates ECR repository if missing
- ✅ **EBS CSI Driver**: Installs and configures for persistent storage
- ✅ **Metrics Server**: Installs Kubernetes metrics server
- ✅ **Monitoring Stack**: Prometheus + Grafana with custom dashboards
- ✅ **Application Build**: Docker build and push to ECR
- ✅ **Application Deployment**: Helm deployment with verification
- ✅ **Complete Verification**: Pods, services, HPA status
- ✅ **Next Steps Guide**: Provides useful commands and cleanup instructions

### **When to use:**
- 🎯 **First-time setup**
- 🎯 **Complete environment deployment**
- 🎯 **Learning and demonstrations**
- 🎯 **YouTube recordings and tutorials**
- 🎯 **Development environment setup**

### **Prerequisites:**
- AWS CLI configured
- Terraform installed
- kubectl installed
- Helm installed
- Docker installed

---

## 🔄 `.github/workflows/deploy.yml` - CI/CD Pipeline

### **Purpose**
Automated application deployment and updates for existing infrastructure.

### **What it does:**
- ✅ **Application Testing**: Node.js dependency installation and tests
- ✅ **Docker Build**: Builds application image
- ✅ **ECR Push**: Pushes image to existing ECR repository
- ✅ **Application Deployment**: Helm upgrade/install
- ✅ **Basic Verification**: Pod and service status
- ✅ **Terraform Plan**: Shows infrastructure changes (PR only)

### **What it assumes:**
- ❌ **Infrastructure already exists** (EKS cluster, VPC, IAM)
- ❌ **ECR repository already exists**
- ❌ **Monitoring already set up**
- ❌ **EBS CSI Driver already installed**

### **When to use:**
- 🎯 **Application updates**
- 🎯 **Continuous deployment**
- 🎯 **After initial setup is complete**
- 🎯 **Automated deployments from Git**

### **Prerequisites:**
- GitHub repository with secrets configured
- Existing AWS infrastructure
- GitHub Actions enabled

---

## 📊 Comparison Table

| Feature | `deploy.sh` | `deploy.yml` |
|---------|-------------|--------------|
| **Infrastructure** | ✅ Creates from scratch | ❌ Assumes exists |
| **ECR Repository** | ✅ Creates if missing | ❌ Must exist |
| **Monitoring** | ✅ Full Prometheus/Grafana | ❌ None |
| **EBS CSI Driver** | ✅ Installs & configures | ❌ Must exist |
| **Metrics Server** | ✅ Installs | ❌ Must exist |
| **Application Testing** | ❌ None | ✅ Node.js tests |
| **Automation** | ❌ Manual execution | ✅ Automated triggers |
| **Infrastructure Plan** | ❌ None | ✅ Terraform plan (PR) |
| **Verification** | ✅ Comprehensive | ✅ Basic |
| **Next Steps** | ✅ Detailed guide | ❌ None |

## 🎯 Recommendation

### **Use `deploy.sh` for:**
- 🚀 **Initial project setup**
- 📹 **YouTube demonstrations**
- 🎓 **Learning and tutorials**
- 🔧 **Development environments**
- 🏗️ **Complete infrastructure deployment**

### **Use `deploy.yml` for:**
- 🔄 **Application updates**
- 🤖 **Automated deployments**
- 📦 **CI/CD pipeline**
- 🔄 **Regular deployments**
- 🏭 **Production workflows**

## 💡 Best Practice Workflow

1. **First time**: Use `./scripts/deploy.sh` to set up everything
2. **Subsequent updates**: Use GitHub Actions `deploy.yml` for app updates
3. **Infrastructure changes**: Use `deploy.sh` or manual Terraform commands
4. **Monitoring updates**: Use `deploy.sh` or manual Helm commands

---

*Both scripts serve different purposes and complement each other in a complete DevOps workflow.* 