# SRE Terraform EKS AWS Incident Scenario

A comprehensive SRE (Site Reliability Engineering) demonstration project that showcases infrastructure provisioning, application deployment, monitoring, and incident response using AWS EKS, Terraform, Helm, and GitHub Actions.

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

The GitHub Actions workflow includes:

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
- Password: `<GRAFANA_PASSWORD>`

## 💰 Cost Optimization

This project is designed for minimal cost:

- **Single NAT Gateway**: Reduces networking costs
- **t3.medium instances**: Cost-effective compute
- **Minimal replicas**: 1-3 pods by default
- **7-day retention**: Limited Prometheus storage
- **Auto-scaling**: Scale down when not needed

**Estimated Monthly Cost**: ~$50-100 USD

## 🧹 Cleanup

```bash
# Delete Helm releases
helm uninstall sre-demo-app
helm uninstall prometheus -n monitoring

# Delete Terraform infrastructure
cd terraform
terraform destroy

# Clean up ECR images
aws ecr batch-delete-image --repository-name sre-demo-app --image-ids imageTag=latest
```

## 📚 Learning Objectives

This project demonstrates:

1. **Infrastructure as Code**: Terraform for AWS resources
2. **Container Orchestration**: Kubernetes/EKS deployment
3. **Application Packaging**: Helm charts for deployment
4. **CI/CD Automation**: GitHub Actions pipeline
5. **Monitoring Setup**: Prometheus and Grafana
6. **Incident Response**: Detection, diagnosis, and resolution
7. **Auto-scaling**: HPA for dynamic scaling
8. **Health Checks**: Liveness and readiness probes

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review the logs and metrics
3. Open an issue on GitHub
4. Contact the DevOps team

---

**Note**: This is a demonstration project. For production use, implement proper security, backup, and disaster recovery procedures. 