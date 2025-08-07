# deploy.sh

**Purpose**: Orchestrates the complete application deployment process to EKS cluster.

**Key Features**:
- Builds Docker image from application code
- Pushes image to ECR registry
- Deploys application using Helm charts
- Installs monitoring stack (Prometheus, Grafana, Metrics Server)
- Verifies deployment health and provides service URLs

**Usage**: `./scripts/deploy.sh`

**Prerequisites**: EKS cluster must be deployed via Terraform first

**Output**: Complete deployment status and service access information 