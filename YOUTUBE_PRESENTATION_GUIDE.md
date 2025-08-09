# 🎥 YouTube Presentation Guide: SRE Terraform EKS AWS Incident Scenario

## 📋 Paulie's Development Environment Dependencies (2025-08-08)

| Tool | Version | Status | Notes |
|------|---------|--------|-------|
| **Git** | 2.25.1 | ✅ Installed | Required for version control |
| **AWS CLI** | 2.28.2 | ✅ Installed | Python/3.13.4, Linux/5.15.133.1-microsoft-standard-WSL2 |
| **Terraform** | 1.8.4 | ✅ Installed | ⚠️ Outdated (latest: 1.12.2) |
| **kubectl** | 1.26.1 | ✅ Installed | Client version, Kustomize v4.5.7 |
| **Helm** | 3.18.4 | ✅ Installed | Go version 1.24.4 |
| **Docker** | 25.0.3 | ✅ Installed | Build 4debf41 |
| **Python** | 3.13.4 | ✅ Installed | Required for AWS CLI and tools |
| **pip** | 25.0.1 | ✅ Updated | Python package manager (user install) |

**AWS Configuration**: ✅ Configured (Account: <YOUR_AWS_ACCOUNT_ID>, User: <YOUR_AWS_USER>)

## 🔐 Required IAM Policies

### **⚠️ Important Note for Viewers**
These are the IAM policies attached to my AWS user account. You'll need similar permissions to run this project.

### **Policy 1: Administrator Access (Full Access)**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}
```

### **Policy 2: AWS Bedrock Access**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "BedrockAll",
            "Effect": "Allow",
            "Action": [
                "bedrock:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "DescribeKey",
            "Effect": "Allow",
            "Action": [
                "kms:DescribeKey"
            ],
            "Resource": "arn:*:kms:*:::*"
        },
        {
            "Sid": "APIsWithAllResourceAccess",
            "Effect": "Allow",
            "Action": [
                "iam:ListRoles",
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups"
            ],
            "Resource": "*"
        },
        {
            "Sid": "MarketplaceModelEndpointMutatingAPIs",
            "Effect": "Allow",
            "Action": [
                "sagemaker:CreateEndpoint",
                "sagemaker:CreateEndpointConfig",
                "sagemaker:CreateModel",
                "sagemaker:DeleteEndpoint",
                "sagemaker:UpdateEndpoint"
            ],
            "Resource": [
                "arn:aws:sagemaker:*:*:endpoint/*",
                "arn:aws:sagemaker:*:*:endpoint-config/*",
                "arn:aws:sagemaker:*:*:model/*"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:CalledViaLast": "bedrock.amazonaws.com",
                    "aws:ResourceTag/sagemaker-sdk:bedrock": "compatible"
                }
            }
        },
        {
            "Sid": "MarketplaceModelEndpointAddTagsOperations",
            "Effect": "Allow",
            "Action": [
                "sagemaker:AddTags"
            ],
            "Resource": [
                "arn:aws:sagemaker:*:*:endpoint/*",
                "arn:aws:sagemaker:*:*:endpoint-config/*",
                "arn:aws:sagemaker:*:*:model/*"
            ],
            "Condition": {
                "ForAllValues:StringEquals": {
                    "aws:TagKeys": [
                        "sagemaker-sdk:bedrock",
                        "bedrock:marketplace-registration-status",
                        "sagemaker-studio:hub-content-arn"
                    ]
                },
                "StringLike": {
                    "aws:RequestTag/sagemaker-sdk:bedrock": "compatible",
                    "aws:RequestTag/bedrock:marketplace-registration-status": "registered",
                    "aws:RequestTag/sagemaker-studio:hub-content-arn": "arn:aws:sagemaker:*:aws:hub-content/SageMakerPublicHub/Model/*"
                }
            }
        },
        {
            "Sid": "MarketplaceModelEndpointDeleteTagsOperations",
            "Effect": "Allow",
            "Action": [
                "sagemaker:DeleteTags"
            ],
            "Resource": [
                "arn:aws:sagemaker:*:*:endpoint/*",
                "arn:aws:sagemaker:*:*:endpoint-config/*",
                "arn:aws:sagemaker:*:*:model/*"
            ],
            "Condition": {
                "ForAllValues:StringEquals": {
                    "aws:TagKeys": [
                        "sagemaker-sdk:bedrock",
                        "bedrock:marketplace-registration-status",
                        "sagemaker-studio:hub-content-arn"
                    ]
                },
                "StringLike": {
                    "aws:ResourceTag/sagemaker-sdk:bedrock": "compatible",
                    "aws:ResourceTag/bedrock:marketplace-registration-status": "registered",
                    "aws:ResourceTag/sagemaker-studio:hub-content-arn": "arn:aws:sagemaker:*:aws:hub-content/SageMakerPublicHub/Model/*"
                }
            }
        },
        {
            "Sid": "MarketplaceModelEndpointNonMutatingAPIs",
            "Effect": "Allow",
            "Action": [
                "sagemaker:DescribeEndpoint",
                "sagemaker:DescribeEndpointConfig",
                "sagemaker:DescribeModel",
                "sagemaker:DescribeInferenceComponent",
                "sagemaker:ListEndpoints",
                "sagemaker:ListTags"
            ],
            "Resource": [
                "arn:aws:sagemaker:*:*:endpoint/*",
                "arn:aws:sagemaker:*:*:endpoint-config/*",
                "arn:aws:sagemaker:*:*:model/*"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:CalledViaLast": "bedrock.amazonaws.com"
                }
            }
        },
        {
            "Sid": "MarketplaceModelEndpointInvokingOperations",
            "Effect": "Allow",
            "Action": [
                "sagemaker:InvokeEndpoint",
                "sagemaker:InvokeEndpointWithResponseStream"
            ],
            "Resource": [
                "arn:aws:sagemaker:*:*:endpoint/*"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:CalledViaLast": "bedrock.amazonaws.com",
                    "aws:ResourceTag/sagemaker-sdk:bedrock": "compatible"
                }
            }
        },
        {
            "Sid": "DiscoveringMarketplaceModel",
            "Effect": "Allow",
            "Action": [
                "sagemaker:DescribeHubContent"
            ],
            "Resource": [
                "arn:aws:sagemaker:*:aws:hub-content/SageMakerPublicHub/Model/*",
                "arn:aws:sagemaker:*:aws:hub/SageMakerPublicHub"
            ]
        },
        {
            "Sid": "AllowMarketplaceModelsListing",
            "Effect": "Allow",
            "Action": [
                "sagemaker:ListHubContents"
            ],
            "Resource": "arn:aws:sagemaker:*:aws:hub/SageMakerPublicHub"
        },
        {
            "Sid": "PassRoleToSageMaker",
            "Effect": "Allow",
            "Action": [
                "iam:PassRole"
            ],
            "Resource": [
                "arn:aws:iam::*:role/*SageMaker*ForBedrock*"
            ],
            "Condition": {
                "StringEquals": {
                    "iam:PassedToService": [
                        "sagemaker.amazonaws.com",
                        "bedrock.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Sid": "PassRoleToBedrock",
            "Effect": "Allow",
            "Action": [
                "iam:PassRole"
            ],
            "Resource": "arn:aws:iam::*:role/*AmazonBedrock*",
            "Condition": {
                "StringEquals": {
                    "iam:PassedToService": [
                        "bedrock.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Sid": "MarketplaceOperationsFromBedrockFor3pModels",
            "Effect": "Allow",
            "Action": [
                "aws-marketplace:Subscribe",
                "aws-marketplace:ViewSubscriptions",
                "aws-marketplace:Unsubscribe"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:CalledViaLast": "bedrock.amazonaws.com"
                }
            }
        }
    ]
}
```

### **Policy 3: Bedrock Provisioned Model Access**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "BedrockProvisionedAccess",
            "Effect": "Allow",
            "Action": [
                "bedrock:ListProvisionedModelThroughputs",
                "bedrock:GetProvisionedModelThroughput",
                "bedrock:CreateProvisionedModelThroughput",
                "bedrock:UpdateProvisionedModelThroughput",
                "bedrock:DeleteProvisionedModelThroughput"
            ],
            "Resource": "*"
        }
    ]
}
```

### **📝 For Viewers:**
- **Minimum Required**: Administrator Access policy for full functionality
- **For AI Features**: Bedrock policies are essential for AWS Bedrock integration
- **Security Note**: These are production-level permissions - use responsibly

---

## 🐍 Python & pip Installation (Prerequisites)

### **Why Python is Required**
Python is needed for AWS CLI and various development tools in this project.

### **Installation Steps**

**1. Check if Python is already installed:**
```bash
python3 --version
python --version
```

**2. Install Python (if not installed):**

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install python3 python3-pip
```

**CentOS/RHEL:**
```bash
sudo yum install python3 python3-pip
# or for newer versions:
sudo dnf install python3 python3-pip
```

**macOS:**
```bash
# Using Homebrew (recommended)
brew install python3

# Or download from https://www.python.org/downloads/
```

**Windows:**
```bash
# Download from https://www.python.org/downloads/
# Make sure to check "Add Python to PATH" during installation
```

**3. Verify pip installation:**
```bash
pip3 --version
pip --version
```

**4. Update pip (recommended):**
```bash
python3 -m pip install --upgrade pip
```

**5. Verify both installations:**
```bash
python3 --version
pip3 --version
```

---

## 📋 Video Structure & Key Points

### **🎯 Important Note**
This manual step-by-step approach will achieve the **exact same result** as running `./scripts/deploy.sh`. The difference is that you'll understand each step and can explain what's happening during your YouTube recording.

**🚀 For Reliable YouTube Recording**: Use `./scripts/deploy.sh` - it includes comprehensive validation, error handling, and automatic troubleshooting for common issues.

**📚 For Educational Purposes**: Follow the manual steps below to understand each component and process.

### 🎯 **Introduction (2-3 minutes)**
- **Project Overview**: "This is an open-source project I've created for the SRE, DevOps, and Cloud community"
- **What we'll build**: "A complete production-like environment with AWS EKS, monitoring, and incident simulation capabilities"
- **Target audience**: "Perfect for SRE engineers, DevOps practitioners, and anyone wanting to learn real-world cloud infrastructure"
- **What you'll learn**: "Infrastructure as Code, Kubernetes deployment, monitoring setup, and incident response"

### 🔧 **Prerequisites Setup (5-7 minutes)**

#### **🖥️ Optional: WSL (Windows Subsystem for Linux) - FIRST STEP**

**For Windows Users Only:**
```powershell
# Check if WSL is available
wsl --list --verbose

# If not installed:
# Enable WSL feature (run in PowerShell as Administrator)
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Restart your computer, then:
wsl --install -d Ubuntu

# After WSL installation, install the tools below in the Ubuntu environment
```
**Explain**: "WSL provides a Linux environment on Windows, making it easier to run these tools. It's optional but recommended for Windows users. Install this FIRST if you're on Windows."

#### **📋 Mandatory Prerequisites**

**1. Git (Required)**
```bash
# Check if Git is installed
git --version

# If not installed:
# Windows: Download from https://git-scm.com/download/win
# macOS: brew install git
# Ubuntu/Debian: sudo apt-get install git
# CentOS/RHEL: sudo yum install git
```
**Explain**: "Git is mandatory for cloning the repository and version control"

**2. AWS Account (Required)**
- **Sign up**: https://aws.amazon.com/
- **Admin access**: "You'll need admin privileges for this demo"
- **Cost warning**: "This will cost $80-150/month, but you can tear it down after"

**⚠️ CRITICAL: AWS Budget Setup (Highly Recommended)**
```bash
# Set up AWS Budgets to avoid unexpected charges
# Go to AWS Console → Billing → Budgets → Create Budget

# Recommended budget settings:
# - Budget amount: $200
# - Alert threshold: 80% ($160)
# - Alert threshold: 100% ($200)
# - Alert threshold: 120% ($240)
```
**Explain**: "Setting up AWS Budgets is HIGHLY RECOMMENDED to prevent unexpected charges. This demo costs money, and you need to be responsible with your AWS spending."

**3. AWS CLI (Required)**
```bash
# Check if AWS CLI is installed
aws --version

# If not installed:
# Windows: Download from https://aws.amazon.com/cli/
# macOS: brew install awscli
# Ubuntu/Debian: sudo apt-get install awscli
# CentOS/RHEL: sudo yum install awscli

# Configure AWS CLI
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your default region (eu-central-1)
# Enter your output format (json)

# Verify configuration
aws sts get-caller-identity
```
**Explain**: "AWS CLI is essential for interacting with AWS services"

**4. Terraform (Required)**
```bash
# Check if Terraform is installed
terraform version

# If not installed:
# Windows: Download from https://www.terraform.io/downloads.html
# macOS: brew install terraform
# Ubuntu/Debian: 
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# CentOS/RHEL:
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install terraform
```
**Explain**: "Terraform version 1.0+ is required for infrastructure provisioning"

**5. kubectl (Required)**
```bash
# Check if kubectl is installed
kubectl version --client

# If not installed:
# Windows: Download from https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
# macOS: brew install kubectl
# Ubuntu/Debian: 
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl

# CentOS/RHEL:
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
sudo yum install -y kubectl
```
**Explain**: "kubectl is needed to manage our Kubernetes cluster"

**6. Helm (Required)**
```bash
# Check if Helm is installed
helm version

# If not installed:
# Windows: Download from https://helm.sh/docs/intro/install/
# macOS: brew install helm
# Ubuntu/Debian: 
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

# CentOS/RHEL:
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```
**Explain**: "Helm is used for deploying applications to Kubernetes"

**7. Docker (Required)**
```bash
# Check if Docker is installed
docker --version

# If not installed:
# Windows: Download Docker Desktop from https://www.docker.com/products/docker-desktop
# macOS: Download Docker Desktop from https://www.docker.com/products/docker-desktop
# Ubuntu/Debian:
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# CentOS/RHEL:
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
```
**Explain**: "Docker is needed to build and push our application images"



#### **🔧 Verification Commands**
```bash
# Option 1: Comprehensive validation (Recommended)
./scripts/validate-setup.sh

# Option 2: Manual verification
echo "=== Prerequisites Check ==="
git --version
aws --version
terraform version
kubectl version --client
helm version
docker --version

# Verify AWS configuration
aws sts get-caller-identity

# Verify Docker is running
docker ps
```
**Explain**: "The validation script checks everything automatically. For manual verification, run the individual commands."

#### **📚 Additional Resources**
- **Official Documentation**: "All installation links are in the project README"
- **Troubleshooting**: "If you encounter issues, check the troubleshooting section"
- **Community Support**: "Join our community discussions for help"

### 🏗️ **Project Architecture Overview (2-3 minutes)**

#### **What We're Building**
- **Infrastructure Layer**: "AWS VPC, EKS cluster, IAM roles, and networking"
- **Application Layer**: "Node.js application with built-in failure simulation"
- **Deployment Layer**: "Kubernetes deployment with Helm charts"
- **Monitoring Layer**: "Prometheus and Grafana for observability"
- **CI/CD Layer**: "GitHub Actions for automated application deployment (infrastructure deployed locally)"

#### **Cost Considerations**
- "This setup costs approximately $80-150/month"
- "Designed to be cost-effective for learning"
- "Easy to tear down when not in use"

### 🚀 **Infrastructure Provisioning (5-7 minutes)**

#### **Option A: Automated Deployment (Recommended)**
```bash
# Use the improved deployment script that handles all edge cases
./scripts/deploy.sh
```
**Explain**: "This script automatically handles all the steps we'll do manually, including validation checks, Lambda building, and troubleshooting common issues."

#### **Option B: Manual Step-by-Step (For Learning)**

#### **Step 1: Clone and Navigate**
```bash
git clone https://github.com/paul123z/SRE-Terraform-EKS-AWS-Incident-Scenario.git
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

#### **Step 5: Build Lambda Function (If Using AI Features)**
```bash
# Build Lambda function for AI incident analysis
./scripts/build-lambda.sh
```
**Explain**: "If you plan to use the AI incident analysis features, build the Lambda function now. This creates the ZIP file that Terraform needs."

#### **Step 6: Apply the Infrastructure**
```bash
terraform apply
```
**Explain**: "This creates all the AWS resources - this will take 10-15 minutes"

**Show**: 
- VPC creation
- EKS cluster provisioning
- Node group setup
- IAM role configuration
- Lambda function creation (if built)

#### **Step 7: Configure kubectl**
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
helm upgrade --install sre-demo-app . \
  --set image.repository=$AWS_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/sre-demo-app \
  --set image.tag=latest \
  --namespace default \
  --create-namespace \
  --wait \
  --timeout 5m
```
**Explain**: "This deploys our application to Kubernetes using Helm with our dynamic account ID. The --wait flag ensures Helm waits for all resources to be ready, and --timeout 5m gives it 5 minutes to complete."

**⚠️ Troubleshooting**: "If the deployment fails with 'serviceaccount not found', it means the Helm chart is missing the service account template. The improved deployment script automatically handles this."

#### **Step 2: Verify Deployment**
```bash
# Check pod status
kubectl get pods -n default

# Check service status
kubectl get svc -n default

# Check deployment status
kubectl get deployments -n default

# Check if pods are ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=sre-demo-app -n default --timeout=300s
```
**Show**: "Our application is now running with load balancing"

**⚠️ Troubleshooting**: "If pods show 'Pending' or 'ContainerCreating' for more than 2-3 minutes, check the pod events with: `kubectl describe pod <pod-name> -n default`"

#### **Step 3: Get the Load Balancer URL**
```bash
# Get the load balancer URL
kubectl get svc sre-demo-app -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# If the above returns empty, wait a bit and try again
sleep 30
kubectl get svc sre-demo-app -n default

# Test the application
SERVICE_URL=$(kubectl get svc sre-demo-app -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application URL: http://$SERVICE_URL"
curl -s http://$SERVICE_URL/health
```
**Explain**: "This gives us the public URL to access our application. AWS load balancers can take 2-5 minutes to be fully available."

**⚠️ Troubleshooting**: "If the load balancer URL is not available immediately, wait 2-5 minutes for AWS to provision it. You can monitor with: `kubectl get svc sre-demo-app -n default -w`"

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

#### **Step 4: Install Kubernetes Dashboard (Optional)**
```bash
# Install Kubernetes Dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Create dashboard admin user
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dashboard-admin
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dashboard-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: dashboard-admin
  namespace: kubernetes-dashboard
EOF

# Wait for dashboard to be ready
kubectl wait --for=condition=ready pod -l app=kubernetes-dashboard -n kubernetes-dashboard --timeout=120s
```
**Explain**: "This installs the Kubernetes Dashboard for cluster management. The wait command ensures the dashboard is fully ready before proceeding."

#### **Step 5: Access Grafana**
```bash
# Option 1: Port forward (for local access)
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Option 2: Load balancer (for external access)
kubectl get svc prometheus-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```
**Show**: "Grafana dashboard at http://localhost:3000 (port forward) or http://<load-balancer-url> (external)"
- **Credentials**: `admin` / `admin123`
- **Navigate to**: Dashboards → Browse
- **Find**: "Kubernetes / Compute Resources / Namespace (Pods)"
- **Explain**: "This dashboard shows real-time CPU and memory usage for all pods in our namespace"

#### **Step 6: Access Kubernetes Dashboard (Optional)**
```bash
# Option 1: Automated access (Recommended)
./scripts/access-dashboard.sh

# Option 2: Manual access
# Start dashboard proxy
kubectl proxy

# Generate access token
./scripts/get-dashboard-token.sh
```
**Show**: "Kubernetes Dashboard at http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
**Explain**: "Use the token from the script to log into the dashboard"

**⚠️ Troubleshooting**: "If you get 'no endpoints available' error, wait a few minutes for the dashboard pods to be ready, or run: `kubectl get pods -n kubernetes-dashboard` to check status"

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
- **Navigate to**: Dashboards → Browse → "Kubernetes / Compute Resources / Namespace (Pods)"
- **Explain**: "This dashboard shows real-time CPU and memory usage for all pods in our namespace"

#### **Step 3: Simulate Memory Leak Incident**
```bash
# Enable memory leak simulation
curl -X POST http://$SERVICE_URL/api/memory-leak \
  -H "Content-Type: application/json" \
  -d '{"enable": true}'
```
**Explain**: "This triggers a memory leak in our application"

#### **Step 4: Show Real-Time Memory Increase**
- **Switch to Grafana**: Navigate to "Kubernetes / Compute Resources / Namespace (Pods)"
- **Focus on**: Memory usage graph for sre-demo-app pods
- **Explain**: "Watch how memory consumption increases over time"
- **Show**: Memory metrics climbing steadily in the graph
- **Point out**: "This is exactly what a real memory leak looks like - memory usage keeps growing"

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

**Optional: Show Kubernetes Dashboard**
- **Switch to browser**: Show Kubernetes Dashboard
- **Navigate to**: Pods → sre-demo-app
- **Show**: Resource usage, logs, and pod status
- **Explain**: "The dashboard provides a visual way to monitor the cluster"

#### **Step 6: Resolve the Incident**
```bash
# Disable memory leak
curl -X POST http://$SERVICE_URL/api/memory-leak \
  -H "Content-Type: application/json" \
  -d '{"enable": false}'
```
**Show**: "Memory usage stabilizes and returns to normal"

#### **Step 7: Show Recovery in Grafana**
- **Switch back to Grafana**: Return to "Kubernetes / Compute Resources / Namespace (Pods)"
- **Focus on**: Memory usage graph for sre-demo-app pods
- **Show**: Memory graph stabilizing and returning to baseline
- **Explain**: "The system recovers and memory usage returns to normal levels"
- **Point out**: "This demonstrates real-time monitoring and incident response capabilities"

### 🤖 **AI-Powered Incident Analysis (4-5 minutes)**

#### **Step 1: Explain Log Storage Strategy**
**Show the audience**: "After running our incident demo, we have logs in TWO places:"
- **Local storage**: `/tmp` directory (for immediate analysis)
- **Cloud storage**: S3 bucket (for remote analysis and backup)

**Visual explanation**:
```
incident-demo.sh
    ↓
├── /tmp/incident-logs/     ← Local analysis
└── S3://bucket/logs/       ← Remote analysis
```

#### **Step 2: Demonstrate Local AI Analysis**
```bash
# Show the local analysis script
./scripts/analyze-incident-bedrock.sh
```
**Explain**: "This script reads logs from `/tmp` and sends them directly to AWS Bedrock using Claude Sonnet 4 for analysis."

**Show the process**:
1. **Read logs** from `/tmp/incident-logs/`
2. **Format prompt** with incident context
3. **Call AWS Bedrock** API with Claude Sonnet 4
4. **Parse response** into structured analysis
5. **Save results** to `bedrock-analysis/` directory

**Display results**: Show the structured analysis output with:
- Incident summary and severity
- Root cause analysis
- Immediate fixes with priorities
- Preventive measures and recommendations

#### **Step 3: Demonstrate GitHub Workflow Analysis**
**Explain**: "Now let's show the CI/CD approach using GitHub Actions."

**Show the workflow**:
```bash
# Navigate to GitHub repository
# Go to Actions tab
# Show analyze-s3-logs.yml workflow
```

**Explain the workflow**:
1. **Trigger**: Manual workflow with S3 object URL parameter
2. **Runner**: Ubuntu with AWS CLI pre-installed
3. **Process**: Download logs from S3, analyze with Bedrock
4. **Output**: Results displayed in workflow console and artifacts

**Show the input**: "We need to provide an S3 object URL like:"
```
https://sre-incident-demo-incident-logs-xxx.s3.eu-central-1.amazonaws.com/incidents/demo-incident-20241201-143022/incident-demo-incident-20241201-143022.log
```

#### **Step 4: Compare Both Methods**
**Create a visual comparison**:

| Method | Location | Use Case | Pros | Cons |
|--------|----------|----------|------|------|
| **Local Analysis** | `/tmp` logs | Immediate analysis | Fast, no network | Requires local setup |
| **GitHub Workflow** | S3 logs | Remote/CI analysis | No local setup, shareable | Requires S3 URL, network |

#### **Step 5: Show AI Analysis Results**
**Display the comprehensive AI analysis output**:

**Incident Summary:**
```json
{
  "type": "Memory leak causing pod restart and HPA metrics failure",
  "severity": "MEDIUM",
  "duration": "Approximately 2 minutes",
  "affected_services": ["sre-demo-app", "horizontal-pod-autoscaler"]
}
```

**Root Cause Analysis:**
```json
{
  "primary_cause": "Memory leak simulation was enabled in the application",
  "contributing_factors": [
    "HPA unable to retrieve CPU and memory metrics",
    "Metrics server connectivity issues",
    "Pod restart disrupted normal operation"
  ]
}
```

**Immediate Fixes:**
```json
[
  {
    "priority": "HIGH",
    "action": "Disabled memory leak simulation",
    "description": "Stopped the root cause of memory consumption"
  },
  {
    "priority": "HIGH",
    "action": "Restarted affected pods",
    "description": "Cleared memory state and restored application"
  }
]
```

#### **Step 6: Explain AI Benefits**
**Highlight the advantages of AI-powered analysis**:

- **⚡ Faster Resolution**: "AI identifies root causes in seconds, not hours"
- **🔍 Comprehensive Analysis**: "Covers technical, process, and preventive aspects"
- **🎯 Actionable Insights**: "Specific recommendations with priorities and timelines"
- **📚 Learning**: "Historical analysis for continuous improvement"
- **🔄 Automation**: "Can be integrated into CI/CD pipelines"

#### **Step 7: Show Real-World Applications**
**Explain practical use cases**:

1. **Production Incidents**: "Use GitHub workflow for team collaboration"
2. **Development Testing**: "Use local analysis for quick feedback"
3. **Post-Incident Reviews**: "Generate structured reports automatically"
4. **Knowledge Base**: "Build incident response playbooks from AI insights"

#### **Step 8: Demonstrate Workflow Integration**
**Show the complete picture**:
```
Incident Demo → Logs (local + S3) → AI Analysis → Actionable Insights
     ↓              ↓                    ↓              ↓
  Real-time      Dual storage       Claude Sonnet    Structured
  simulation     for flexibility      4 analysis      recommendations
```

**Explain**: "This creates a complete incident response system that works both locally and in the cloud, perfect for SRE teams."

### 🧹 **Cleanup & Cost Management (3-4 minutes)**

#### **⚠️ CRITICAL: You MUST Destroy Infrastructure**

**Emphasize**: "This is the MOST IMPORTANT part of the demo. You MUST destroy the infrastructure to avoid ongoing AWS charges!"

#### **Step 1: Show Current Costs**
```bash
# Check what resources are running
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name]' --output table

# Show EKS cluster
aws eks describe-cluster --name sre-incident-demo-cluster --region eu-central-1 --query 'cluster.status'

# Show load balancers
aws elbv2 describe-load-balancers --query 'LoadBalancers[*].[LoadBalancerArn,LoadBalancerName,State.Code]' --output table
```
**Explain**: "These resources are costing money right now. Let's destroy them immediately."

#### **Step 2: Automated Cleanup (Recommended)**
```bash
# Run the automated teardown script
./scripts/teardown.sh
```
**Explain**: "This script will destroy ALL AWS resources created by this demo. This is essential to avoid ongoing charges."

**Show the script output**: "Watch as it removes each resource - VPC, EKS cluster, load balancers, etc."

#### **Step 3: Manual Terraform Destroy (Alternative)**
```bash
# If automated script fails, use Terraform
cd terraform
terraform destroy -auto-approve
cd ..
```
**Explain**: "This is the backup method to ensure everything is destroyed."

#### **Step 4: Verification**
```bash
# Verify all resources are gone
./scripts/teardown-verify.sh
```
**Show**: "This script checks that all resources have been properly destroyed."

#### **Step 5: Final Cost Check**
```bash
# Check AWS billing (if you have access)
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-02 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```
**Explain**: "Monitor your AWS billing to ensure no unexpected charges."

#### **⚠️ Important Reminders**
- **"DO NOT leave this infrastructure running"** - it costs money
- **"Set up AWS Budgets"** - to get alerts if you forget
- **"Check your AWS billing dashboard"** - regularly
- **"This demo costs $80-150/month if left running"** - emphasize the cost

#### **Cost Management Best Practices**
```bash
# Set up AWS Budgets (if not done already)
# Go to AWS Console → Billing → Budgets → Create Budget
# - Budget amount: $200
# - Alert at 80%, 100%, 120%
# - Email notifications for alerts
```
**Explain**: "AWS Budgets will alert you if spending exceeds your limits. This is crucial for cost management."

### 🔧 **Troubleshooting Common Issues (2-3 minutes)**

#### **Helm Deployment Issues**
```bash
# If Helm deployment fails with service account error
kubectl describe deployment sre-demo-app -n default
kubectl describe replicaset <replicaset-name> -n default

# Check if service account exists
kubectl get serviceaccount -n default

# If service account is missing, create it manually
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sre-demo-app
  namespace: default
EOF
```

#### **Pod Issues**
```bash
# Check pod status and events
kubectl get pods -n default
kubectl describe pod <pod-name> -n default

# Check pod logs
kubectl logs <pod-name> -n default

# Check if image pull issues
kubectl describe pod <pod-name> -n default | grep -A 10 Events
```

#### **Service Issues**
```bash
# Check service status
kubectl get svc -n default
kubectl describe svc sre-demo-app -n default

# If service is missing, create manually
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: sre-demo-app
  namespace: default
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 3000
      protocol: TCP
  selector:
    app.kubernetes.io/name: sre-demo-app
    app.kubernetes.io/instance: sre-demo-app
EOF
```

#### **Load Balancer Issues**
```bash
# Wait for load balancer provisioning
kubectl get svc sre-demo-app -n default -w

# Check load balancer events
kubectl describe svc sre-demo-app -n default

# Test connectivity (may take 2-5 minutes)
SERVICE_URL=$(kubectl get svc sre-demo-app -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl -v http://$SERVICE_URL/health
```

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
| Monitoring | 5-6 min | Prometheus, Grafana, and K8s Dashboard |
| Demo | 6-8 min | Incident simulation |
| AI Analysis | 4-5 min | AI-powered incident analysis using AWS Bedrock. After running incident-demo.sh (which pushes logs to /tmp and S3), demonstrate two analysis methods: 1) Local analysis with analyze-incident-bedrock.sh using logs from /tmp, or 2) GitHub workflow analyze-s3-logs.yml using Ubuntu runner with AWS CLI and S3 object URL parameter |
| Cleanup | 3-4 min | Cost management |
| Wrap-up | 2-3 min | Takeaways and next steps |

**Total Estimated Time**: 40-51 minutes

## 🚀 **Ready to Record!**

This guide provides a comprehensive framework for your YouTube presentation. Remember to:
- Practice the commands beforehand
- Have a backup plan for any failures
- Engage with your audience
- Share the open-source spirit of the project

Good luck with your video! 🎥✨ 