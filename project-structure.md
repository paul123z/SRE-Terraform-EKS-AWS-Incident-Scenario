# SRE Terraform EKS AWS Incident Scenario - Project Structure

A comprehensive open-source project designed for the SRE, DevOps, and Cloud community to learn and practice real-world incident response, infrastructure management, and monitoring in a production-like AWS EKS environment.

## 📁 Project Structure Overview

```
SRE-Terraform-EKS-AWS-Incident-Scenario/
├── 📄 README.md                           # Main project documentation and setup guide
├── 📄 project-structure.md                # This file - project structure documentation
├── 📄 .gitignore                          # Git ignore rules
│
├── 🏗️ terraform/                          # Infrastructure as Code (IaC)
│   ├── 📄 main.tf                        # Main Terraform configuration
│   ├── 📄 variables.tf                   # Variable definitions
│   ├── 📄 outputs.tf                     # Output values
│   └── 📄 terraform.tfstate*             # Terraform state files (auto-generated)
│
├── 🐳 app/                                # Application Source Code
│   ├── 📄 server.js                      # Node.js Express application
│   ├── 📄 package.json                   # Node.js dependencies
│   └── 📄 Dockerfile                     # Container image definition
│
├── 🎯 helm/                               # Kubernetes Deployment Management
│   └── sre-demo-app/                     # Helm chart for the demo application
│       ├── 📄 Chart.yaml                 # Helm chart metadata
│       ├── 📄 values.yaml                # Default configuration values
│       └── templates/                    # Kubernetes manifest templates
│           ├── 📄 deployment.yaml        # Application deployment
│           ├── 📄 service.yaml           # Load balancer service
│           └── 📄 hpa.yaml               # Horizontal Pod Autoscaler
│
├── 🔍 monitoring/                         # Observability Configuration
│   └── 📄 prometheus-values.yaml         # Prometheus/Grafana Helm values
│
├── 🔄 .github/                            # CI/CD Pipeline Configuration
│   └── workflows/                        # GitHub Actions workflows
│       └── 📄 deploy.yml                 # Main deployment workflow
│
├── 🛠️ scripts/                            # Automation and Utility Scripts
│   ├── 📄 README.md                      # Scripts documentation
│   ├── 📄 deploy.sh                      # Complete deployment automation
│   ├── 📄 teardown.sh                    # Infrastructure cleanup
│   ├── 📄 teardown-verify.sh             # Cleanup verification
│   ├── 📄 incident-simulator.sh          # Incident simulation automation
│   ├── 📄 incident-demo.sh               # Interactive incident demo
│   ├── 📄 deploy-app-only.sh             # Application-only deployment
│   ├── 📄 build-and-push.sh              # Docker build and push
│   └── 📄 get-dashboard-token.sh         # Grafana access token retrieval
│
├── 📋 Documentation/                      # Comprehensive Documentation
│   ├── 📄 DEPLOYMENT_SUMMARY.md          # Deployment process documentation
│   ├── 📄 INCIDENT_WALKTHROUGH.md        # Step-by-step incident response guide
│   ├── 📄 INCIDENT_DETECTION_RESOLUTION.md # Incident detection and resolution
│   ├── 📄 FRESH_DEPLOYMENT_CHECKLIST.md  # Deployment checklist
│   └── 📄 PATH_FIXES_SUMMARY.md          # Common issues and fixes
│
└── 🔧 aws-auth-patch.yaml                # AWS authentication configuration
```

## 🎯 Component Explanations

### 🏗️ **Infrastructure Layer (terraform/)**
**Purpose**: Defines and manages the AWS infrastructure using Infrastructure as Code principles.

**Key Components**:
- **main.tf**: Core infrastructure definition including VPC, EKS cluster, and IAM roles
- **variables.tf**: Configurable parameters for customization across environments
- **outputs.tf**: Exported values for use by other components and scripts

**Benefits**: 
- Reproducible infrastructure deployments
- Version-controlled infrastructure changes
- Cost-optimized configuration for learning environments

### 🐳 **Application Layer (app/)**
**Purpose**: Contains the demo application with built-in failure simulation capabilities.

**Key Components**:
- **server.js**: Express.js application with health checks and failure simulation endpoints
- **package.json**: Node.js dependencies and scripts
- **Dockerfile**: Container image definition for consistent deployment

**Benefits**:
- Realistic application behavior for incident training
- Controllable failure modes for systematic testing
- Lightweight and fast deployment

### 🎯 **Deployment Layer (helm/)**
**Purpose**: Manages Kubernetes deployments with production-ready configurations.

**Key Components**:
- **Chart.yaml**: Helm chart metadata and versioning
- **values.yaml**: Default configuration values
- **templates/**: Kubernetes manifest templates for deployment, service, and autoscaling

**Benefits**:
- Production-ready deployment configuration
- Built-in high availability and auto-scaling
- Proper resource management and monitoring integration

### 🔍 **Monitoring Layer (monitoring/)**
**Purpose**: Provides comprehensive observability and alerting capabilities.

**Key Components**:
- **prometheus-values.yaml**: Pre-configured Prometheus and Grafana setup

**Benefits**:
- Complete observability stack for incident detection
- Pre-built dashboards for quick monitoring setup
- Cost-optimized storage and resource allocation

### 🔄 **CI/CD Layer (.github/)**
**Purpose**: Automates the build, test, and deployment process.

**Key Components**:
- **workflows/deploy.yml**: GitHub Actions workflow for automated deployment

**Benefits**:
- Automated deployment pipeline reduces human error
- Consistent deployment process across environments
- Built-in testing and validation steps

### 🛠️ **Automation Layer (scripts/)**
**Purpose**: Provides automation for common operational tasks and incident simulation.

**Key Scripts**:
- **deploy.sh**: Complete environment setup automation
- **teardown.sh**: Clean infrastructure removal
- **incident-simulator.sh**: Automated incident simulation
- **incident-demo.sh**: Interactive incident response training

**Benefits**:
- One-command deployment and teardown
- Automated incident simulation for training
- Consistent environment setup across team members

### 📋 **Documentation Layer**
**Purpose**: Comprehensive documentation for learning and reference.

**Key Documents**:
- **README.md**: Main project guide and quick start
- **INCIDENT_WALKTHROUGH.md**: Step-by-step incident response training
- **DEPLOYMENT_SUMMARY.md**: Detailed deployment process documentation
- **FRESH_DEPLOYMENT_CHECKLIST.md**: Deployment verification checklist

**Benefits**:
- Self-contained learning resource
- Clear step-by-step instructions
- Troubleshooting guides and best practices

## 🚀 **Project Philosophy**

This project is designed as an **open-source contribution to the SRE, DevOps, and Cloud community**, providing:

1. **Real-world Scenarios**: Production-like environments for realistic training
2. **Best Practices**: Industry-standard tools and methodologies
3. **Learning Focus**: Comprehensive documentation and guided walkthroughs
4. **Community Driven**: Designed for sharing knowledge and improving skills
5. **Cost Conscious**: Optimized for learning without excessive AWS costs

## 🎯 **Target Audience**

- **SRE Engineers**: Practice incident response and infrastructure management
- **DevOps Engineers**: Learn modern deployment and monitoring practices
- **Cloud Engineers**: Understand AWS EKS and Terraform best practices
- **Students**: Learn real-world cloud infrastructure and operations
- **Teams**: Conduct incident response training and skill development

## 🔧 **Technology Stack**

- **Infrastructure**: AWS EKS, Terraform, VPC, IAM
- **Application**: Node.js, Express.js, Docker
- **Orchestration**: Kubernetes, Helm
- **Monitoring**: Prometheus, Grafana
- **CI/CD**: GitHub Actions
- **Automation**: Bash scripting, AWS CLI

This project serves as a comprehensive learning platform for modern cloud-native operations and incident response practices.
