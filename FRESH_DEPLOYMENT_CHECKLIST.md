# 🚀 Fresh Deployment Checklist

This checklist ensures that `./scripts/deploy.sh` will work perfectly from scratch.

## ✅ **Prerequisites (Must be installed)**

### **Required Tools:**
- [ ] **AWS CLI** - Installed and configured with credentials
- [ ] **Terraform** - Installed (v1.0+)
- [ ] **kubectl** - Installed and working
- [ ] **Helm** - Installed (v3.x)
- [ ] **Docker** - Installed and running

### **AWS Configuration:**
- [ ] **AWS credentials configured** - `aws configure` or environment variables
- [ ] **Admin permissions** - User has sufficient IAM permissions for EKS, ECR, EC2, VPC, IAM
- [ ] **Region set** - All scripts configured for `eu-central-1`

## ✅ **Files Updated and Ready**

### **Core Application:**
- [x] **`app/server.js`** - Updated with aggressive memory leak (50MB every 3 seconds)
- [x] **`app/Dockerfile`** - Includes curl for debugging
- [x] **`app/package.json`** - Unix line endings, proper dependencies

### **Infrastructure:**
- [x] **`terraform/main.tf`** - 2 nodes minimum, eu-central-1 region
- [x] **`terraform/variables.tf`** - eu-central-1 region configured
- [x] **`terraform/outputs.tf`** - All outputs defined

### **Helm Charts:**
- [x] **`helm/sre-demo-app/values.yaml`** - 2Gi memory limits, eu-central-1 region
- [x] **`helm/sre-demo-app/templates/`** - All templates updated
- [x] **`monitoring/prometheus-values.yaml`** - Monitoring configuration

### **Scripts (All AWS CLI Path Fixed):**
- [x] **`scripts/deploy.sh`** - Complete automation, AWS CLI path fix
- [x] **`scripts/teardown.sh`** - Complete cleanup, AWS CLI path fix
- [x] **`scripts/build-and-push.sh`** - AWS CLI path fix
- [x] **`scripts/incident-demo.sh`** - Enhanced memory leak demo
- [x] **`scripts/incident-simulator.sh`** - Interactive simulation
- [x] **`scripts/deploy-app-only.sh`** - App-only deployment
- [x] **`scripts/get-dashboard-token.sh`** - Dashboard access

### **CI/CD:**
- [x] **`.github/workflows/deploy.yml`** - Manual trigger only, eu-central-1
- [x] **`.github/workflows/deploy-app-only.yml`** - Manual trigger only

### **Documentation:**
- [x] **`README.md`** - Complete documentation, eu-central-1
- [x] **`DEPLOYMENT_SUMMARY.md`** - Quick reference
- [x] **`INCIDENT_DETECTION_RESOLUTION.md`** - Detailed walkthrough
- [x] **`scripts/README.md`** - Script documentation

## ✅ **Key Features Implemented**

### **Infrastructure:**
- [x] **EKS Cluster** - 2 nodes minimum for high availability
- [x] **VPC with private/public subnets** - Proper networking
- [x] **ECR Repository** - Container registry
- [x] **Load Balancer** - Application access
- [x] **IAM Roles** - Proper permissions

### **Application:**
- [x] **Node.js Express app** - Sample application
- [x] **Memory leak simulation** - 50MB every 3 seconds
- [x] **Health checks** - Liveness and readiness probes
- [x] **Auto-scaling** - HPA configured
- [x] **curl included** - For debugging

### **Monitoring:**
- [x] **Prometheus** - Metrics collection
- [x] **Grafana** - Visualization and dashboards
- [x] **Metrics Server** - Resource monitoring
- [x] **EBS CSI Driver** - Persistent volumes

### **Incident Simulation:**
- [x] **Memory leak** - Aggressive simulation
- [x] **Health check failures** - Various failure modes
- [x] **Slow responses** - Performance issues
- [x] **CPU stress** - Resource exhaustion

## ✅ **Deployment Process**

### **One-Command Deployment:**
```bash
./scripts/deploy.sh
```

**What it does:**
1. ✅ Checks all prerequisites
2. ✅ Creates ECR repository
3. ✅ Deploys infrastructure (EKS, VPC, networking)
4. ✅ Builds and pushes Docker image
5. ✅ Deploys application with Helm
6. ✅ Installs EBS CSI Driver and Metrics Server
7. ✅ Sets up monitoring (Prometheus/Grafana)
8. ✅ Verifies deployment
9. ✅ Shows next steps

### **Expected Output:**
- **Application URL** - Load balancer endpoint
- **Grafana Dashboard** - Monitoring access
- **All pods running** - Application and monitoring
- **2 EKS nodes** - High availability

## ✅ **Testing and Demo**

### **Incident Demo:**
```bash
./scripts/incident-demo.sh
```

**Features:**
- ✅ Disables HPA during demo
- ✅ Shows memory growth over 30 seconds
- ✅ Demonstrates detection and resolution
- ✅ Re-enables HPA after demo

### **Interactive Simulation:**
```bash
./scripts/incident-simulator.sh
```

**Options:**
- ✅ Memory leak simulation
- ✅ Health check failures
- ✅ Resource monitoring
- ✅ Scaling and restart

## ✅ **Cleanup Process**

### **Complete Teardown:**
```bash
./scripts/teardown.sh
```

**What it removes:**
- ✅ EKS cluster and nodes
- ✅ VPC and networking
- ✅ ECR repository and images
- ✅ IAM roles and policies
- ✅ Monitoring stack
- ✅ Local Terraform files

## ✅ **Troubleshooting**

### **Common Issues:**
- ✅ **AWS CLI path** - Fixed in all scripts
- ✅ **Memory limits** - Increased to 2Gi
- ✅ **Node capacity** - 2 nodes minimum
- ✅ **EBS CSI Driver** - Automated installation
- ✅ **Metrics Server** - Automated installation

### **Verification Commands:**
```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Check application
kubectl get pods -l app.kubernetes.io/name=sre-demo-app
kubectl get svc sre-demo-app

# Check monitoring
kubectl get pods -n monitoring
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

## ✅ **Cost Optimization**

### **Features:**
- ✅ **2 nodes minimum** - High availability without excess
- ✅ **t3.medium instances** - Cost-effective compute
- ✅ **Single NAT Gateway** - Reduced networking costs
- ✅ **7-day retention** - Limited Prometheus storage
- ✅ **Auto-scaling** - Scale down when not needed

### **Estimated Cost:**
- **Monthly**: ~€80-150 EUR (eu-central-1)
- **Per hour**: ~€0.10-0.20 EUR

## ✅ **Ready for Production Demo**

The entire project is now:
- ✅ **Fully automated** - One command deployment
- ✅ **Region configured** - eu-central-1
- ✅ **AWS CLI compatible** - Works with any AWS CLI installation
- ✅ **Comprehensive monitoring** - Prometheus + Grafana
- ✅ **Incident simulation** - Realistic SRE scenarios
- ✅ **Complete documentation** - All aspects covered
- ✅ **Easy cleanup** - Complete teardown script

**Next time you deploy:**
1. Run `./scripts/deploy.sh`
2. Wait ~15-20 minutes for complete deployment
3. Run `./scripts/incident-demo.sh` for SRE demo
4. Run `./scripts/teardown.sh` when done

Everything will work out of the box! 🎉 