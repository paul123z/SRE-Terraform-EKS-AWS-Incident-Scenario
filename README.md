# SRE Terraform EKS AWS Incident Scenario

A comprehensive open-source project designed for the SRE, DevOps, and Cloud community to learn and practice real-world incident response, infrastructure management, and monitoring in a production-like AWS EKS environment. This project showcases modern cloud-native practices using AWS EKS, Terraform, Helm, and GitHub Actions.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub Repo   │    │   GitHub Actions│    │   AWS ECR       │
│                 │    │   CI/CD Pipeline│    │   Container     │
│   Source Code   │───▶│                 │───▶│   Registry      │
│   Helm Charts   │    │   Build & Deploy│    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Prometheus    │    │   EKS Cluster   │    │   Application   │
│   Grafana       │◀───│   (Kubernetes)  │◀───│   Load Balancer │
│   Monitoring    │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📋 Project Setup Components

This open-source SRE project consists of several interconnected components, each serving a specific purpose in creating a realistic production-like environment for incident response training and infrastructure management practice. Designed for the SRE, DevOps, and Cloud community to learn and share knowledge.

### 🏗️ **Infrastructure Setup (Terraform)**
**Purpose**: Creates the foundational AWS infrastructure needed to run the application and monitoring stack.

**What it sets up**:
- **VPC with Public/Private Subnets**: Creates a secure network topology with public subnets for load balancers and private subnets for application pods
- **EKS Cluster**: Provisions a Kubernetes cluster with managed node groups using t3.medium instances for cost optimization
- **IAM Roles & Policies**: Configures necessary permissions for EKS nodes to pull images from ECR and manage networking
- **Single NAT Gateway**: Reduces costs while providing internet access to private subnets
- **Auto-scaling Node Groups**: Allows the cluster to scale between 1-3 nodes based on demand

**Key Benefits**: 
- Infrastructure as Code (IaC) approach ensures reproducible deployments
- Cost-optimized configuration suitable for learning and demos
- Production-ready security with proper network isolation

### 🐳 **Application Setup (Docker + Node.js)**
**Purpose**: Provides a realistic application with built-in failure modes for incident simulation.

**What it includes**:
- **Express.js Web Server**: Simple but realistic application with health checks and API endpoints
- **Failure Simulation Endpoints**: Built-in mechanisms to simulate various failure scenarios:
  - Health check failures (503 errors)
  - Slow response times (timeout scenarios)
  - Memory leaks (gradual memory consumption)
  - CPU stress (high resource utilization)
- **External API Integration**: Simulates real-world dependencies with external service calls
- **Monitoring Endpoints**: Exposes metrics for Prometheus scraping

**Key Benefits**:
- Realistic application behavior for incident response training
- Controllable failure modes for systematic testing
- Lightweight and fast deployment

### 🎯 **Deployment Setup (Helm Charts)**
**Purpose**: Manages the Kubernetes deployment with production-like configurations.

**What it configures**:
- **Multi-replica Deployment**: Runs 2 replicas by default with auto-scaling capabilities
- **Load Balancer Service**: Exposes the application externally with proper load balancing
- **Resource Limits**: Sets CPU and memory constraints to prevent resource exhaustion
- **Health Checks**: Configures liveness and readiness probes for Kubernetes orchestration
- **Horizontal Pod Autoscaler (HPA)**: Automatically scales pods based on CPU/memory usage
- **Service Monitor**: Enables Prometheus to scrape application metrics

**Key Benefits**:
- Production-ready deployment configuration
- Built-in high availability and auto-scaling
- Proper resource management and monitoring integration

### 🔍 **Monitoring Setup (Prometheus + Grafana)**
**Purpose**: Provides comprehensive observability and alerting capabilities.

**What it deploys**:
- **Prometheus Server**: Collects and stores time-series metrics from the application and Kubernetes
- **Grafana Dashboards**: Pre-configured dashboards for application health, resource usage, and error rates
- **Alert Manager**: Handles alert routing and notification management
- **Custom Dashboards**: SRE-specific dashboards showing application health, pod status, and resource utilization
- **7-day Retention**: Optimized storage configuration for demo purposes

**Key Benefits**:
- Complete observability stack for incident detection
- Pre-built dashboards for quick monitoring setup
- Cost-optimized storage and resource allocation

### 🔄 **CI/CD Setup (GitHub Actions)**
**Purpose**: Automates the build, test, and deployment process for continuous delivery.

**What it automates**:
- **Testing Phase**: Runs Node.js tests to validate application functionality
- **Build Phase**: Creates Docker images and pushes them to AWS ECR
- **Deployment Phase**: Uses Helm to deploy updated applications to EKS
- **Verification**: Checks deployment status and application health
- **Multi-environment Support**: Can be extended for staging/production environments

**Key Benefits**:
- Automated deployment pipeline reduces human error
- Consistent deployment process across environments
- Built-in testing and validation steps

### 🚨 **Incident Simulation Setup (Scripts)**
**Purpose**: Provides tools and scenarios for realistic incident response training.

**What it includes**:
- **Automated Incident Scripts**: Pre-built scenarios for common failure modes
- **Manual Control Endpoints**: API endpoints to trigger specific failure conditions
- **Incident Walkthroughs**: Step-by-step guides for detection, diagnosis, and resolution
- **Monitoring Integration**: Alerts and dashboards that respond to simulated incidents

**Key Benefits**:
- Realistic training environment for SRE teams
- Repeatable incident scenarios for consistent learning
- Integration with real monitoring and alerting systems

### 🛠️ **Utility Scripts Setup**
**Purpose**: Provides automation for common operational tasks.

**What it includes**:
- **Deployment Scripts**: Automated setup of the entire environment
- **Teardown Scripts**: Clean removal of all resources to avoid costs
- **Incident Simulator**: Automated triggering of various failure scenarios
- **Health Check Scripts**: Validation of deployment and application status

**Key Benefits**:
- One-command deployment and teardown
- Automated incident simulation for training
- Consistent environment setup across team members

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with admin access
- Terraform >= 1.0
- kubectl
- Helm >= 3.0
- Docker

### 1. Infrastructure Setup

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Plan the infrastructure
terraform plan

# Apply the infrastructure
terraform apply

# Get cluster info
aws eks update-kubeconfig --region eu-central-1 --name sre-incident-demo-cluster
```

### 2. Application Deployment

```bash
# Build and push the application image
cd app
docker build -t sre-demo-app .
docker tag sre-demo-app:latest <your-aws-account>.dkr.ecr.eu-central-1.amazonaws.com/sre-demo-app:latest
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin <your-aws-account>.dkr.ecr.eu-central-1.amazonaws.com
docker push <your-aws-account>.dkr.ecr.eu-central-1.amazonaws.com/sre-demo-app:latest

# Deploy using Helm
cd ../helm/sre-demo-app
helm install sre-demo-app . --set image.repository=<your-aws-account>.dkr.ecr.eu-central-1.amazonaws.com/sre-demo-app
```

### 3. Monitoring Setup

```bash
# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus with Grafana
helm install prometheus prometheus-community/kube-prometheus-stack \
  -f monitoring/prometheus-values.yaml \
  --namespace monitoring \
  --create-namespace
```

## 📊 Application Features

The sample application includes:

- **Health Check Endpoints**: `/health` for liveness and readiness probes
- **API Endpoints**: `/api/data` for external API simulation
- **Incident Simulation**: Built-in failure modes for testing
- **Resource Monitoring**: CPU and memory usage tracking
- **Auto-scaling**: Horizontal Pod Autoscaler configuration

### API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Application info and status |
| `/health` | GET | Health check endpoint |
| `/api/data` | GET | External API simulation |
| `/api/stress` | GET | CPU stress test |
| `/api/failure-mode` | POST | Set failure simulation mode |
| `/api/memory-leak` | POST | Enable/disable memory leak |
| `/api/cpu-stress` | POST | Enable/disable CPU stress |

## 🚨 Incident Simulation

### Available Scenarios

1. **Health Check Failure**: Application returns 503 on health checks
2. **Slow Response**: Health checks timeout due to slow processing
3. **Memory Leak**: Gradual memory consumption increase
4. **CPU Stress**: High CPU utilization simulation

### Running Incident Simulations

```bash
# Make the script executable
chmod +x scripts/incident-simulator.sh

# Run the incident simulator
./scripts/incident-simulator.sh
```

### Manual Incident Simulation

```bash
# Get the service URL
kubectl get svc sre-demo-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Simulate health check failure
curl -X POST http://<service-url>/api/failure-mode \
  -H "Content-Type: application/json" \
  -d '{"mode": "health_failure"}'

# Simulate memory leak
curl -X POST http://<service-url>/api/memory-leak \
  -H "Content-Type: application/json" \
  -d '{"enable": true}'

# Reset simulations
curl -X POST http://<service-url>/api/failure-mode \
  -H "Content-Type: application/json" \
  -d '{"mode": "none"}'
```

## 🔧 Troubleshooting

### Common Issues

#### Prometheus/Grafana Pods Stuck in Pending
If you see Prometheus or Grafana pods stuck in `Pending` status with volume binding errors:

```bash
# Check PVC status
kubectl get pvc -n monitoring

# Check pod events
kubectl describe pod prometheus-grafana-<hash> -n monitoring
```

**Solution**: The deployment script automatically installs the EBS CSI Driver and configures IAM permissions. If you encounter this issue manually:

```bash
# Install EBS CSI Driver
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update
helm upgrade --install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver --namespace kube-system

# Get node group role and attach policy
NODE_GROUP_NAME=$(aws eks list-nodegroups --cluster-name sre-incident-demo-cluster --region eu-central-1 --query 'nodegroups[0]' --output text)
NODE_GROUP_ROLE=$(aws eks describe-nodegroup --cluster-name sre-incident-demo-cluster --nodegroup-name $NODE_GROUP_NAME --region eu-central-1 --query 'nodegroup.nodeRole' --output text | cut -d'/' -f2)
aws iam attach-role-policy --role-name $NODE_GROUP_ROLE --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy
```

#### Application Pods Not Starting
If your application pods are not starting:

```bash
# Check pod status
kubectl get pods -l app.kubernetes.io/name=sre-demo-app

# Check pod events
kubectl describe pod <pod-name>

# Check service account
kubectl get serviceaccount sre-demo-app
```

**Solution**: Create the missing service account:
```bash
kubectl create serviceaccount sre-demo-app
```

## 🔍 Incident Response Walkthrough

### 1. Detection

**Monitoring Alerts**:
- Prometheus alerts for high CPU/memory usage
- Kubernetes events for pod failures
- Application health check failures

**Manual Detection**:
```bash
# Check pod status
kubectl get pods -l app.kubernetes.io/name=sre-demo-app

# Check pod logs
kubectl logs -l app.kubernetes.io/name=sre-demo-app

# Check resource usage
kubectl top pods -l app.kubernetes.io/name=sre-demo-app
```

### 2. Diagnosis

**Investigation Steps**:
```bash
# Check application health
curl http://<service-url>/health

# Check pod events
kubectl describe pod <pod-name>

# Check HPA status
kubectl get hpa

# Check service endpoints
kubectl get endpoints sre-demo-app
```

### 3. Resolution

**Common Fixes**:
```bash
# Scale up the application
kubectl scale deployment sre-demo-app --replicas=3

# Restart the application
kubectl rollout restart deployment sre-demo-app

# Check rollout status
kubectl rollout status deployment sre-demo-app
```

## 🛠️ CI/CD Pipeline

The project includes multiple GitHub Actions workflows:

### **deploy.yml** - Full Infrastructure & Application Deployment
- **Trigger**: Manual (`workflow_dispatch`)
- **Purpose**: Complete end-to-end deployment
- **Steps**: Infrastructure → Build → Push → Deploy → Monitoring

### **build-push-deploy-app.yml** - Build, Push & Deploy Application
- **Trigger**: Manual (`workflow_dispatch`)
- **Purpose**: Build new image and deploy application
- **Steps**: Build → Push → Deploy → Verify
- **Use case**: When you've updated application code and want to deploy

### **deploy-app-only.yml** - Application Deployment Only
- **Trigger**: Manual (`workflow_dispatch`)
- **Purpose**: Deploy existing application image
- **Steps**: Deploy → Verify
- **Use case**: When you want to redeploy the same image

### Workflow Features:
1. **Testing**: Node.js application tests
2. **Building**: Docker image build
3. **Pushing**: ECR image push
4. **Deploying**: Helm chart deployment
5. **Verification**: Deployment status check

### GitHub Secrets Required

- `AWS_ACCESS_KEY_ID`: AWS access key
- `AWS_SECRET_ACCESS_KEY`: AWS secret key

## 📈 Monitoring & Observability

### Prometheus Metrics

- Application health status
- CPU and memory usage
- HTTP request metrics
- Pod restart counts

### Grafana Dashboards

- Application health overview
- Resource utilization graphs
- Error rate monitoring
- Response time tracking

### Accessing Dashboards

```bash
# Get Grafana service URL
kubectl get svc -n monitoring prometheus-grafana

# Port forward to access locally
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

**Default Credentials**:
- Username: `admin`
- Password: `<GRAFANA_PASSWORD>` (can be changed via GRAFANA_PASSWORD environment variable)

## 💰 Cost Optimization

This project is designed for minimal cost:

- **Single NAT Gateway**: Reduces networking costs
- **t3.medium instances**: Cost-effective compute
- **2 nodes minimum**: For high availability and pod capacity
- **Minimal replicas**: 1-3 pods by default
- **7-day retention**: Limited Prometheus storage
- **Auto-scaling**: Scale down when not needed

**Estimated Monthly Cost**: ~$80-150 USD (with 2 nodes for high availability)

## 🧹 Cleanup

### Option 1: Automated Teardown (Recommended)
```bash
# One-command teardown
./scripts/teardown.sh
```

### Option 2: Manual Teardown
```bash
# Delete Helm releases
helm uninstall sre-demo-app
helm uninstall prometheus -n monitoring

# Delete Terraform infrastructure
cd terraform
terraform destroy

# Clean up ECR images
aws ecr batch-delete-image --repository-name sre-demo-app --image-ids imageTag=latest --region eu-central-1
```

### Option 3: Partial Cleanup (Keep Infrastructure)
```bash
# Remove only application (keep EKS cluster)
helm uninstall sre-demo-app

# Remove only monitoring (keep EKS cluster)
helm uninstall prometheus -n monitoring
```

## 📚 Learning Objectives

This open-source project demonstrates modern cloud-native practices:

1. **Infrastructure as Code**: Terraform for AWS resources
2. **Container Orchestration**: Kubernetes/EKS deployment
3. **Application Packaging**: Helm charts for deployment
4. **CI/CD Automation**: GitHub Actions pipeline
5. **Monitoring Setup**: Prometheus and Grafana
6. **Incident Response**: Detection, diagnosis, and resolution
7. **Auto-scaling**: HPA for dynamic scaling
8. **Health Checks**: Liveness and readiness probes

## 🤝 Contributing

This is an open-source project for the SRE, DevOps, and Cloud community. We welcome contributions!

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Community Guidelines
- Follow best practices for SRE and DevOps
- Add comprehensive documentation for new features
- Include tests and validation scripts
- Consider cost implications for the community

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔒 Security Considerations

### **Before First Deployment**
1. **AWS Authentication**: Copy `aws-auth-patch.template.yaml` to `aws-auth-patch.yaml` and update with your AWS account details
2. **Grafana Password**: Set `GRAFANA_PASSWORD` environment variable to change the default password
3. **AWS Credentials**: Configure AWS CLI with your credentials (`aws configure`)

### **Security Best Practices**
- ✅ Never commit AWS credentials or access keys
- ✅ Use IAM roles with minimal required permissions
- ✅ Regularly rotate passwords and access keys
- ✅ Enable AWS CloudTrail for audit logging
- ✅ Use VPC security groups to restrict access

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review the logs and metrics
3. Open an issue on GitHub
4. Join the community discussions

---

**Note**: This is an open-source learning project designed for the SRE, DevOps, and Cloud community. For production use, implement proper security, backup, and disaster recovery procedures. 