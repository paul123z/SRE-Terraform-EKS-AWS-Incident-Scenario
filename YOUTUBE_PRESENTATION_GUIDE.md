# 🎥 YouTube Presentation Guide: SRE Terraform EKS AWS Incident Scenario

## 📋 Video Structure & Key Points

### **🎯 Important Note**
This manual step-by-step approach will achieve the **exact same result** as running `./scripts/deploy.sh`. The difference is that you'll understand each step and can explain what's happening during your YouTube recording.

### 🎯 **Introduction (2-3 minutes)**
- **Project Overview**: "This is an open-source project I've created for the SRE, DevOps, and Cloud community"
- **What we'll build**: "A complete production-like environment with AWS EKS, monitoring, and incident simulation capabilities"
- **Target audience**: "Perfect for SRE engineers, DevOps practitioners, and anyone wanting to learn real-world cloud infrastructure"
- **What you'll learn**: "Infrastructure as Code, Kubernetes deployment, monitoring setup, and incident response"

### 🔧 **Prerequisites Setup (3-4 minutes)**

#### **Required Tools & Accounts**
1. **AWS Account**: "You'll need an AWS account with admin access"
2. **AWS CLI**: "Install and configure AWS CLI with your credentials"
   - Show: `aws configure` command
   - Verify: `aws sts get-caller-identity`
3. **Terraform**: "Install Terraform version 1.0 or higher"
   - Show: `terraform version`
4. **kubectl**: "Install kubectl for Kubernetes management"
   - Show: `kubectl version --client`
5. **Helm**: "Install Helm for Kubernetes package management"
   - Show: `helm version`
6. **Docker**: "Install Docker for building container images"
   - Show: `docker --version`

#### **GitHub Setup** (if using CI/CD)
- **GitHub Account**: "For CI/CD pipeline and repository hosting"
- **Repository Fork**: "Fork the project to your GitHub account"
- **GitHub Secrets**: "Configure AWS credentials as GitHub secrets"

### 🏗️ **Project Architecture Overview (2-3 minutes)**

#### **What We're Building**
- **Infrastructure Layer**: "AWS VPC, EKS cluster, IAM roles, and networking"
- **Application Layer**: "Node.js application with built-in failure simulation"
- **Deployment Layer**: "Kubernetes deployment with Helm charts"
- **Monitoring Layer**: "Prometheus and Grafana for observability"
- **CI/CD Layer**: "GitHub Actions for automated deployment"

#### **Cost Considerations**
- "This setup costs approximately $80-150/month"
- "Designed to be cost-effective for learning"
- "Easy to tear down when not in use"

### 🚀 **Infrastructure Provisioning (5-7 minutes)**

#### **Step 1: Clone and Navigate**
```bash
git clone <your-repo-url>
cd SRE-Terraform-EKS-AWS-Incident-Scenario

# Set up environment variables for the session
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: $AWS_ACCOUNT_ID"
```

#### **Step 2: Terraform Initialization**
```bash
cd terraform
terraform init
```
**Explain**: "This downloads the required Terraform providers and modules"

#### **Step 3: Review the Configuration**
- Show `main.tf`: "This creates our VPC, EKS cluster, and IAM roles"
- Show `variables.tf`: "These are configurable parameters"
- Show `outputs.tf`: "These are values we'll need later"

#### **Step 4: Plan the Infrastructure**
```bash
terraform plan
```
**Explain**: "This shows us exactly what resources will be created"

#### **Step 5: Apply the Infrastructure**
```bash
terraform apply
```
**Explain**: "This creates all the AWS resources - this will take 10-15 minutes"

**Show**: 
- VPC creation
- EKS cluster provisioning
- Node group setup
- IAM role configuration

#### **Step 6: Configure kubectl**
```bash
aws eks update-kubeconfig --region eu-central-1 --name sre-incident-demo-cluster
kubectl get nodes
```
**Explain**: "Now we can interact with our Kubernetes cluster"

### 🐳 **Application Build & Push (3-4 minutes)**

#### **Step 1: Build the Docker Image**
```bash
cd ../app
docker build -t sre-demo-app .
```
**Explain**: "This creates a container image from our Node.js application"

#### **Step 2: Get Your AWS Account ID**
```bash
# Get your AWS account ID dynamically
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Your AWS Account ID: $AWS_ACCOUNT_ID"
```
**Explain**: "This gets your AWS account ID automatically - no need to hardcode it"

#### **Step 3: Tag for ECR**
```bash
docker tag sre-demo-app:latest $AWS_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/sre-demo-app:latest
```
**Explain**: "We tag the image using our dynamic AWS account ID"

#### **Step 4: Login to ECR**
```bash
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com
```
**Explain**: "This authenticates Docker with our ECR repository"

#### **Step 5: Push to ECR**
```bash
docker push $AWS_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/sre-demo-app:latest
```
**Explain**: "This uploads our image to AWS ECR"

### 🎯 **Application Deployment (3-4 minutes)**

#### **Step 1: Deploy with Helm**
```bash
cd ../helm/sre-demo-app
helm install sre-demo-app . --set image.repository=$AWS_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/sre-demo-app
```
**Explain**: "This deploys our application to Kubernetes using Helm with our dynamic account ID"

#### **Step 2: Verify Deployment**
```bash
kubectl get pods
kubectl get services
```
**Show**: "Our application is now running with load balancing"

#### **Step 3: Get the Load Balancer URL**
```bash
kubectl get svc sre-demo-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```
**Explain**: "This gives us the public URL to access our application"

### 🔍 **Monitoring Setup (3-4 minutes)**

#### **Step 1: Add Prometheus Repository**
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

#### **Step 2: Install EBS CSI Driver (Required for Monitoring)**
```bash
# Add EBS CSI Driver repository
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update

# Install EBS CSI Driver
helm upgrade --install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver --namespace kube-system

# Get node group role and attach policy
NODE_GROUP_NAME=$(aws eks list-nodegroups --cluster-name sre-incident-demo-cluster --region eu-central-1 --query 'nodegroups[0]' --output text)
NODE_GROUP_ROLE=$(aws eks describe-nodegroup --cluster-name sre-incident-demo-cluster --nodegroup-name $NODE_GROUP_NAME --region eu-central-1 --query 'nodegroup.nodeRole' --output text | cut -d'/' -f2)
aws iam attach-role-policy --role-name $NODE_GROUP_ROLE --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy
```
**Explain**: "This enables persistent storage for Prometheus and Grafana"

#### **Step 3: Install Monitoring Stack**
```bash
helm install prometheus prometheus-community/kube-prometheus-stack \
  -f ../monitoring/prometheus-values.yaml \
  --namespace monitoring \
  --create-namespace
```
**Explain**: "This installs Prometheus and Grafana for monitoring"

#### **Step 4: Access Grafana**
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```
**Show**: "Grafana dashboard with pre-configured SRE dashboards"

### 🚨 **Incident Simulation Demo (6-8 minutes)**

#### **Step 1: Show Normal Operation**
```bash
# Get the load balancer URL
SERVICE_URL=$(kubectl get svc sre-demo-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application URL: http://$SERVICE_URL"
```
- Visit the application URL: `http://$SERVICE_URL`
- Show health check endpoint: `curl http://$SERVICE_URL/health`
- Show normal metrics in Grafana dashboard
- **Explain**: "This is our baseline - everything is healthy"

#### **Step 2: Access Grafana Dashboard**
```bash
# Port forward to access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```
- **Show**: Grafana dashboard at `http://localhost:3000`
- **Credentials**: `admin` / `admin123`
- **Navigate to**: SRE Demo Dashboard
- **Explain**: "We can see CPU, memory, and application health metrics"

#### **Step 3: Simulate Memory Leak Incident**
```bash
# Enable memory leak simulation
curl -X POST http://$SERVICE_URL/api/memory-leak \
  -H "Content-Type: application/json" \
  -d '{"enable": true}'
```
**Explain**: "This triggers a memory leak in our application"

#### **Step 4: Show Real-Time Memory Increase**
- **Switch to Grafana**: Show memory usage graph
- **Explain**: "Watch how memory consumption increases over time"
- **Show**: Memory metrics climbing steadily
- **Point out**: "This is exactly what a real memory leak looks like"

#### **Step 5: Demonstrate Incident Response**
```bash
# Check pod status
kubectl get pods -l app.kubernetes.io/name=sre-demo-app

# Check resource usage
kubectl top pods -l app.kubernetes.io/name=sre-demo-app

# Show pod logs
kubectl logs -l app.kubernetes.io/name=sre-demo-app
```
**Explain**: "This is how an SRE would investigate the incident"

#### **Step 6: Resolve the Incident**
```bash
# Disable memory leak
curl -X POST http://$SERVICE_URL/api/memory-leak \
  -H "Content-Type: application/json" \
  -d '{"enable": false}'
```
**Show**: "Memory usage stabilizes and returns to normal"

#### **Step 7: Show Recovery in Grafana**
- **Switch back to Grafana**: Show memory graph stabilizing
- **Explain**: "The system recovers and metrics return to baseline"
- **Point out**: "This demonstrates real-time monitoring and incident response"

### 🧹 **Cleanup & Cost Management (2-3 minutes)**

#### **Option 1: Automated Cleanup**
```bash
./scripts/teardown.sh
```
**Explain**: "This removes all AWS resources to avoid costs"

#### **Option 2: Verification**
```bash
./scripts/teardown-verify.sh
```
**Show**: "This verifies that all resources have been cleaned up"

### 🎯 **Key Takeaways & Next Steps (2-3 minutes)**

#### **What We've Accomplished**
- ✅ Complete infrastructure as code with Terraform
- ✅ Production-ready Kubernetes deployment
- ✅ Comprehensive monitoring and alerting
- ✅ Realistic incident simulation capabilities
- ✅ Automated CI/CD pipeline

#### **Learning Opportunities**
- **Infrastructure as Code**: "Terraform best practices"
- **Kubernetes**: "Real-world deployment patterns"
- **Monitoring**: "Observability in practice"
- **Incident Response**: "Hands-on troubleshooting"

#### **Community Contribution**
- "This is an open-source project - contributions welcome!"
- "Fork, experiment, and share your improvements"
- "Perfect for learning and teaching others"

## 🔒 **Security Considerations**

### **Terraform State Files**
- ✅ **Already fixed**: Added `*.tfstate*` to `.gitignore`
- ✅ **Best practice**: Never commit state files to public repositories
- ✅ **Alternative**: Use remote state storage (S3 + DynamoDB) for production

### **AWS Credentials**
- ✅ **Never commit**: AWS credentials or access keys
- ✅ **Use IAM roles**: For production environments
- ✅ **GitHub secrets**: For CI/CD pipeline

## 📝 **Video Production Tips**

### **Screen Recording Setup**
- **Resolution**: 1920x1080 or higher
- **Frame rate**: 30fps for smooth playback
- **Audio**: Clear microphone, minimal background noise

### **Code Display**
- **Font size**: Large enough to read (14pt+)
- **Syntax highlighting**: Use your IDE's theme
- **Terminal**: Use a readable font (Fira Code, JetBrains Mono)

### **Pacing**
- **Speed**: Not too fast, allow viewers to follow along
- **Pauses**: Brief pauses when running commands
- **Explanations**: Explain what each command does

### **Engagement**
- **Questions**: "What do you think will happen when we run this?"
- **Tips**: Share best practices and gotchas
- **Community**: Encourage comments and questions

## 🎬 **Video Timeline Summary**

| Section | Duration | Key Points |
|---------|----------|------------|
| Introduction | 2-3 min | Project overview, target audience |
| Prerequisites | 3-4 min | Tool installation and verification |
| Architecture | 2-3 min | What we're building |
| Infrastructure | 5-7 min | Terraform deployment |
| Build & Push | 3-4 min | Docker and ECR |
| Deployment | 3-4 min | Helm and Kubernetes |
| Monitoring | 4-5 min | Prometheus and Grafana |
| Demo | 6-8 min | Incident simulation |
| Cleanup | 2-3 min | Cost management |
| Wrap-up | 2-3 min | Takeaways and next steps |

**Total Estimated Time**: 35-45 minutes

## 🚀 **Ready to Record!**

This guide provides a comprehensive framework for your YouTube presentation. Remember to:
- Practice the commands beforehand
- Have a backup plan for any failures
- Engage with your audience
- Share the open-source spirit of the project

Good luck with your video! 🎥✨ 