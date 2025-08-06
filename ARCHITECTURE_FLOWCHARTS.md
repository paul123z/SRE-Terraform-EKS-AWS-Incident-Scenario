# 🏗️ Architecture Flowcharts

This document provides comprehensive flowcharts showing the architecture and data flow of the SRE Terraform EKS AWS Incident Scenario project.

## 🎯 **Better Visualization Options**

### **📱 For YouTube Video & Presentations:**

#### **Option 1: Mermaid Live Editor (Recommended)**
1. **Copy each Mermaid code block** from the sections below
2. **Go to**: https://mermaid.live/
3. **Paste the code** in the left panel
4. **Export as PNG/SVG** using the download button
5. **Use in your video** - much better quality and zoom!

#### **Option 2: VS Code Extensions**
- **Mermaid Preview**: Install "Mermaid Preview" extension
- **Markdown Preview Enhanced**: Install "Markdown Preview Enhanced"
- **Right-click** on Mermaid code → "Open Preview" → **Full-screen mode**

#### **Option 3: Online Tools**
- **Draw.io**: Import Mermaid code or recreate diagrams
- **Lucidchart**: Professional diagramming
- **Figma**: Modern design tool with diagram capabilities

#### **Option 4: Command Line Export**
```bash
# Install mermaid-cli
npm install -g @mermaid-js/mermaid-cli

# Export specific diagram
mmdc -i flowchart.mmd -o flowchart.png -b transparent

# Export all diagrams
for file in *.mmd; do
    mmdc -i "$file" -o "${file%.mmd}.png" -b transparent
done
```

### **🎬 YouTube Video Tips:**
- **Export as PNG** with high resolution (1920x1080 or higher)
- **Use full-screen** during presentation
- **Zoom in** on specific components when explaining
- **Add annotations** in video editing software
- **Show code** alongside diagrams for technical details

---

## 📋 Table of Contents

- [🏗️ Architecture Flowcharts](#️-architecture-flowcharts)
  - [🎯 **Better Visualization Options**](#-better-visualization-options)
    - [**📱 For YouTube Video \& Presentations:**](#-for-youtube-video--presentations)
      - [**Option 1: Mermaid Live Editor (Recommended)**](#option-1-mermaid-live-editor-recommended)
      - [**Option 2: VS Code Extensions**](#option-2-vs-code-extensions)
      - [**Option 3: Online Tools**](#option-3-online-tools)
      - [**Option 4: Command Line Export**](#option-4-command-line-export)
    - [**🎬 YouTube Video Tips:**](#-youtube-video-tips)
  - [📋 Table of Contents](#-table-of-contents)
  - [🎯 Complete System Overview](#-complete-system-overview)
  - [🏗️ Infrastructure Provisioning Flow](#️-infrastructure-provisioning-flow)
  - [🔄 CI/CD Pipeline Flow](#-cicd-pipeline-flow)
  - [🚀 Application Deployment Flow](#-application-deployment-flow)
  - [📊 Monitoring \& Observability Flow](#-monitoring--observability-flow)
  - [🚨 Incident Response \& AI Analysis Flow](#-incident-response--ai-analysis-flow)
  - [🔄 Data Flow Architecture](#-data-flow-architecture)
  - [📋 Architecture Summary](#-architecture-summary)
    - [**Key Components:**](#key-components)
    - [**Data Flow:**](#data-flow)
    - [**Key Benefits:**](#key-benefits)

---

## 🎯 Complete System Overview

```mermaid
graph TB
    subgraph "GitHub Repository"
        GH[GitHub Repo]
        GH_ACTIONS[GitHub Actions]
        GH_SECRETS[GitHub Secrets]
    end
    
    subgraph "Local Development"
        LOCAL[Local Machine]
        DOCKER[Docker Build]
        TF[Terraform]
        KUBECTL[kubectl]
    end
    
    subgraph "AWS Cloud"
        subgraph "VPC & Networking"
            VPC[VPC]
            PUB_SUBNET[Public Subnets]
            PRIV_SUBNET[Private Subnets]
            NAT[NAT Gateway]
            IGW[Internet Gateway]
        end
        
        subgraph "EKS Cluster"
            EKS[EKS Cluster]
            NODES[Worker Nodes]
            PODS[Application Pods]
        end
        
        subgraph "AWS Services"
            ECR[ECR Registry]
            S3[S3 Bucket]
            LAMBDA[Lambda Function]
            BEDROCK[AWS Bedrock]
            CLOUDWATCH[CloudWatch]
        end
        
        subgraph "Load Balancing"
            ALB[Application Load Balancer]
            TARGET_GROUP[Target Groups]
        end
    end
    
    subgraph "Kubernetes Resources"
        subgraph "Application Layer"
            DEPLOYMENT[Deployment]
            SERVICE[Service]
            HPA[HPA]
            INGRESS[Ingress]
        end
        
        subgraph "Monitoring Stack"
            PROMETHEUS[Prometheus]
            GRAFANA[Grafana]
            ALERTMANAGER[Alert Manager]
        end
    end
    
    subgraph "AI Incident Response"
        LOGS[Incident Logs]
        AI_ANALYSIS[AI Analysis]
        RCA_REPORT[RCA Report]
    end
    
    %% GitHub to Local
    GH -->|Clone| LOCAL
    GH -->|Trigger| GH_ACTIONS
    
    %% Local to AWS
    LOCAL -->|Terraform Apply| TF
    TF -->|Provision| VPC
    TF -->|Create| EKS
    TF -->|Setup| ECR
    TF -->|Deploy| S3
    TF -->|Create| LAMBDA
    
    %% CI/CD Pipeline
    GH_ACTIONS -->|Build| DOCKER
    DOCKER -->|Push| ECR
    GH_ACTIONS -->|Deploy| KUBECTL
    KUBECTL -->|Apply| DEPLOYMENT
    
    %% Application Flow
    ECR -->|Pull Image| PODS
    PODS -->|Expose| SERVICE
    SERVICE -->|Route| ALB
    ALB -->|Traffic| TARGET_GROUP
    TARGET_GROUP -->|Forward| PODS
    
    %% Monitoring Flow
    PODS -->|Metrics| PROMETHEUS
    PROMETHEUS -->|Dashboards| GRAFANA
    PROMETHEUS -->|Alerts| ALERTMANAGER
    
    %% Incident Response Flow
    PODS -->|Logs| LOGS
    LOGS -->|Upload| S3
    S3 -->|Retrieve| LAMBDA
    LAMBDA -->|Analyze| BEDROCK
    BEDROCK -->|Results| AI_ANALYSIS
    AI_ANALYSIS -->|Generate| RCA_REPORT
    
    %% Networking
    VPC -->|Contains| PUB_SUBNET
    VPC -->|Contains| PRIV_SUBNET
    PUB_SUBNET -->|Hosts| NAT
    PUB_SUBNET -->|Hosts| ALB
    PRIV_SUBNET -->|Hosts| NODES
    NAT -->|Internet Access| IGW
    
    %% EKS Components
    EKS -->|Manages| NODES
    NODES -->|Run| PODS
    PODS -->|Managed by| DEPLOYMENT
    DEPLOYMENT -->|Scaled by| HPA
    
    %% Monitoring Integration
    PROMETHEUS -->|Scrape| PODS
    GRAFANA -->|Query| PROMETHEUS
    CLOUDWATCH -->|Logs| LAMBDA
    
    classDef github fill:#24292e,stroke:#0366d6,stroke-width:2px,color:#fff
    classDef aws fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#000
    classDef k8s fill:#326CE5,stroke:#326CE5,stroke-width:2px,color:#fff
    classDef monitoring fill:#F15922,stroke:#F15922,stroke-width:2px,color:#fff
    classDef ai fill:#8B5CF6,stroke:#8B5CF6,stroke-width:2px,color:#fff
    
    class GH,GH_ACTIONS,GH_SECRETS github
    class VPC,PUB_SUBNET,PRIV_SUBNET,NAT,IGW,EKS,NODES,ECR,S3,LAMBDA,BEDROCK,CLOUDWATCH,ALB,TARGET_GROUP aws
    class PODS,DEPLOYMENT,SERVICE,HPA,INGRESS k8s
    class PROMETHEUS,GRAFANA,ALERTMANAGER monitoring
    class LOGS,AI_ANALYSIS,RCA_REPORT ai
```

---

## 🏗️ Infrastructure Provisioning Flow

```mermaid
graph TD
    subgraph "Terraform Execution"
        TF_INIT[terraform init]
        TF_PLAN[terraform plan]
        TF_APPLY[terraform apply]
    end
    
    subgraph "AWS Resources Created"
        subgraph "Networking"
            VPC[VPC Creation]
            SUBNETS[Subnets Creation]
            ROUTE_TABLES[Route Tables]
            NAT_GW[NAT Gateway]
            IGW[Internet Gateway]
            SECURITY_GROUPS[Security Groups]
        end
        
        subgraph "EKS Cluster"
            EKS_CLUSTER[EKS Cluster]
            NODE_GROUPS[Node Groups]
            IAM_ROLES[IAM Roles]
            CLUSTER_ROLE[Cluster IAM Role]
            NODE_ROLE[Node IAM Role]
        end
        
        subgraph "Supporting Services"
            ECR_REPO[ECR Repository]
            S3_BUCKET[S3 Bucket]
            LAMBDA_FUNC[Lambda Function]
            CLOUDWATCH_LOGS[CloudWatch Logs]
        end
    end
    
    subgraph "Configuration"
        KUBECONFIG[Update kubeconfig]
        HELM_REPO[Add Helm repos]
        NAMESPACES[Create namespaces]
    end
    
    %% Flow
    TF_INIT --> TF_PLAN
    TF_PLAN --> TF_APPLY
    
    TF_APPLY --> VPC
    VPC --> SUBNETS
    SUBNETS --> ROUTE_TABLES
    ROUTE_TABLES --> NAT_GW
    NAT_GW --> IGW
    VPC --> SECURITY_GROUPS
    
    TF_APPLY --> EKS_CLUSTER
    EKS_CLUSTER --> NODE_GROUPS
    EKS_CLUSTER --> IAM_ROLES
    IAM_ROLES --> CLUSTER_ROLE
    IAM_ROLES --> NODE_ROLE
    
    TF_APPLY --> ECR_REPO
    TF_APPLY --> S3_BUCKET
    TF_APPLY --> LAMBDA_FUNC
    LAMBDA_FUNC --> CLOUDWATCH_LOGS
    
    EKS_CLUSTER --> KUBECONFIG
    KUBECONFIG --> HELM_REPO
    HELM_REPO --> NAMESPACES
    
    classDef terraform fill:#7B42BC,stroke:#7B42BC,stroke-width:2px,color:#fff
    classDef aws fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#000
    classDef config fill:#326CE5,stroke:#326CE5,stroke-width:2px,color:#fff
    
    class TF_INIT,TF_PLAN,TF_APPLY terraform
    class VPC,SUBNETS,ROUTE_TABLES,NAT_GW,IGW,SECURITY_GROUPS,EKS_CLUSTER,NODE_GROUPS,IAM_ROLES,CLUSTER_ROLE,NODE_ROLE,ECR_REPO,S3_BUCKET,LAMBDA_FUNC,CLOUDWATCH_LOGS aws
    class KUBECONFIG,HELM_REPO,NAMESPACES config
```

---

## 🔄 CI/CD Pipeline Flow

```mermaid
graph LR
    subgraph "GitHub Repository"
        CODE[Source Code]
        WORKFLOW[GitHub Actions Workflow]
        SECRETS[AWS Credentials]
    end
    
    subgraph "Build Phase"
        DOCKER_BUILD[Docker Build]
        DOCKER_TAG[Docker Tag]
        DOCKER_PUSH[Docker Push to ECR]
    end
    
    subgraph "Deploy Phase"
        HELM_UPDATE[Helm Update]
        K8S_DEPLOY[Kubernetes Deploy]
        HEALTH_CHECK[Health Check]
    end
    
    subgraph "AWS Services"
        ECR[ECR Registry]
        EKS[EKS Cluster]
    end
    
    %% Triggers
    CODE -->|Push to main| WORKFLOW
    WORKFLOW -->|Manual trigger| SECRETS
    
    %% Build Process
    WORKFLOW --> DOCKER_BUILD
    DOCKER_BUILD --> DOCKER_TAG
    DOCKER_TAG --> DOCKER_PUSH
    DOCKER_PUSH --> ECR
    
    %% Deploy Process
    WORKFLOW --> HELM_UPDATE
    HELM_UPDATE --> K8S_DEPLOY
    K8S_DEPLOY --> EKS
    K8S_DEPLOY --> HEALTH_CHECK
    
    %% Verification
    HEALTH_CHECK -->|Success| SUCCESS[✅ Deployment Success]
    HEALTH_CHECK -->|Failure| FAILURE[❌ Deployment Failed]
    
    classDef github fill:#24292e,stroke:#0366d6,stroke-width:2px,color:#fff
    classDef build fill:#00D4AA,stroke:#00D4AA,stroke-width:2px,color:#000
    classDef deploy fill:#FF6B6B,stroke:#FF6B6B,stroke-width:2px,color:#fff
    classDef aws fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#000
    
    class CODE,WORKFLOW,SECRETS github
    class DOCKER_BUILD,DOCKER_TAG,DOCKER_PUSH build
    class HELM_UPDATE,K8S_DEPLOY,HEALTH_CHECK deploy
    class ECR,EKS aws
```

---

## 🚀 Application Deployment Flow

```mermaid
graph TD
    subgraph "Docker Image"
        DOCKERFILE[Dockerfile]
        APP_CODE[Node.js Application]
        DOCKER_IMAGE[Docker Image]
    end
    
    subgraph "ECR Registry"
        ECR_REPO[ECR Repository]
        IMAGE_TAG[Image Tag]
    end
    
    subgraph "Kubernetes Deployment"
        HELM_CHART[Helm Chart]
        DEPLOYMENT[Deployment]
        SERVICE[Service]
        HPA[HPA]
        INGRESS[Ingress]
    end
    
    subgraph "EKS Cluster"
        NODES[Worker Nodes]
        PODS[Application Pods]
        LOAD_BALANCER[Load Balancer]
    end
    
    %% Docker Build
    DOCKERFILE --> DOCKER_IMAGE
    APP_CODE --> DOCKER_IMAGE
    
    %% ECR Push
    DOCKER_IMAGE --> ECR_REPO
    ECR_REPO --> IMAGE_TAG
    
    %% Kubernetes Deploy
    HELM_CHART --> DEPLOYMENT
    DEPLOYMENT --> PODS
    PODS --> SERVICE
    SERVICE --> LOAD_BALANCER
    DEPLOYMENT --> HPA
    SERVICE --> INGRESS
    
    %% Node Scheduling
    NODES --> PODS
    
    %% Health Checks
    PODS -->|Health Check| HEALTH[Health Status]
    HEALTH -->|Ready| READY[✅ Ready]
    HEALTH -->|Not Ready| NOT_READY[❌ Not Ready]
    
    classDef docker fill:#2496ED,stroke:#2496ED,stroke-width:2px,color:#fff
    classDef ecr fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#000
    classDef k8s fill:#326CE5,stroke:#326CE5,stroke-width:2px,color:#fff
    classDef health fill:#00D4AA,stroke:#00D4AA,stroke-width:2px,color:#000
    
    class DOCKERFILE,APP_CODE,DOCKER_IMAGE docker
    class ECR_REPO,IMAGE_TAG ecr
    class HELM_CHART,DEPLOYMENT,SERVICE,HPA,INGRESS,NODES,PODS,LOAD_BALANCER k8s
    class HEALTH,READY,NOT_READY health
```

---

## 📊 Monitoring & Observability Flow

```mermaid
graph TB
    subgraph "Application Layer"
        APP_PODS[Application Pods]
        APP_METRICS[Application Metrics]
        APP_LOGS[Application Logs]
    end
    
    subgraph "Kubernetes Layer"
        K8S_METRICS[Kubernetes Metrics]
        K8S_EVENTS[Kubernetes Events]
        NODE_METRICS[Node Metrics]
    end
    
    subgraph "Prometheus Stack"
        PROMETHEUS[Prometheus Server]
        SERVICE_MONITOR[Service Monitor]
        POD_MONITOR[Pod Monitor]
        NODE_EXPORTER[Node Exporter]
        KUBE_STATE_METRICS[Kube State Metrics]
    end
    
    subgraph "Grafana Dashboards"
        APP_DASHBOARD[Application Dashboard]
        K8S_DASHBOARD[Kubernetes Dashboard]
        NODE_DASHBOARD[Node Dashboard]
        CUSTOM_DASHBOARD[Custom SRE Dashboard]
    end
    
    subgraph "Alerting"
        ALERT_RULES[Alert Rules]
        ALERT_MANAGER[Alert Manager]
        NOTIFICATIONS[Notifications]
    end
    
    %% Metrics Collection
    APP_PODS --> APP_METRICS
    APP_PODS --> APP_LOGS
    APP_PODS --> K8S_METRICS
    APP_PODS --> K8S_EVENTS
    
    %% Prometheus Scraping
    SERVICE_MONITOR --> APP_METRICS
    POD_MONITOR --> APP_METRICS
    NODE_EXPORTER --> NODE_METRICS
    KUBE_STATE_METRICS --> K8S_METRICS
    
    %% Prometheus Storage
    APP_METRICS --> PROMETHEUS
    K8S_METRICS --> PROMETHEUS
    NODE_METRICS --> PROMETHEUS
    
    %% Grafana Queries
    PROMETHEUS --> APP_DASHBOARD
    PROMETHEUS --> K8S_DASHBOARD
    PROMETHEUS --> NODE_DASHBOARD
    PROMETHEUS --> CUSTOM_DASHBOARD
    
    %% Alerting
    PROMETHEUS --> ALERT_RULES
    ALERT_RULES --> ALERT_MANAGER
    ALERT_MANAGER --> NOTIFICATIONS
    
    classDef app fill:#00D4AA,stroke:#00D4AA,stroke-width:2px,color:#000
    classDef k8s fill:#326CE5,stroke:#326CE5,stroke-width:2px,color:#fff
    classDef prometheus fill:#E6522C,stroke:#E6522C,stroke-width:2px,color:#fff
    classDef grafana fill:#F46800,stroke:#F46800,stroke-width:2px,color:#fff
    classDef alerting fill:#FF6B6B,stroke:#FF6B6B,stroke-width:2px,color:#fff
    
    class APP_PODS,APP_METRICS,APP_LOGS app
    class K8S_METRICS,K8S_EVENTS,NODE_METRICS k8s
    class PROMETHEUS,SERVICE_MONITOR,POD_MONITOR,NODE_EXPORTER,KUBE_STATE_METRICS prometheus
    class APP_DASHBOARD,K8S_DASHBOARD,NODE_DASHBOARD,CUSTOM_DASHBOARD grafana
    class ALERT_RULES,ALERT_MANAGER,NOTIFICATIONS alerting
```

---

## 🚨 Incident Response & AI Analysis Flow

```mermaid
graph TD
    subgraph "Incident Trigger"
        INCIDENT_DEMO[incident-demo.sh]
        MEMORY_LEAK[Memory Leak Simulation]
        CPU_STRESS[CPU Stress Simulation]
        HEALTH_FAILURE[Health Check Failure]
    end
    
    subgraph "Data Collection"
        APP_LOGS[Application Logs]
        K8S_LOGS[Kubernetes Logs]
        METRICS[Resource Metrics]
        EVENTS[Kubernetes Events]
    end
    
    subgraph "Local Processing"
        LOG_DIR[Local Log Directory]
        INCIDENT_ID[Incident ID Generation]
        LOG_FILES[Log Files]
    end
    
    subgraph "S3 Storage"
        S3_BUCKET[S3 Bucket]
        INCIDENT_FOLDER[incidents folder]
        LOG_UPLOAD[Log Upload]
    end
    
    subgraph "AI Analysis"
        LAMBDA[Lambda Function]
        BEDROCK[AWS Bedrock]
        CLAUDE[Claude 3 Sonnet]
        AI_ANALYSIS[AI Analysis]
    end
    
    subgraph "RCA Report"
        INCIDENT_SUMMARY[Incident Summary]
        ROOT_CAUSE[Root Cause Analysis]
        IMMEDIATE_FIXES[Immediate Fixes]
        PREVENTIVE_MEASURES[Preventive Measures]
        LESSONS_LEARNED[Lessons Learned]
        RECOMMENDATIONS[Recommendations]
    end
    
    %% Incident Simulation
    INCIDENT_DEMO --> MEMORY_LEAK
    INCIDENT_DEMO --> CPU_STRESS
    INCIDENT_DEMO --> HEALTH_FAILURE
    
    %% Data Collection
    MEMORY_LEAK --> APP_LOGS
    CPU_STRESS --> APP_LOGS
    HEALTH_FAILURE --> APP_LOGS
    
    APP_LOGS --> K8S_LOGS
    APP_LOGS --> METRICS
    APP_LOGS --> EVENTS
    
    %% Local Processing
    APP_LOGS --> LOG_DIR
    K8S_LOGS --> LOG_DIR
    METRICS --> LOG_DIR
    EVENTS --> LOG_DIR
    
    LOG_DIR --> INCIDENT_ID
    INCIDENT_ID --> LOG_FILES
    
    %% S3 Upload
    LOG_FILES --> S3_BUCKET
    S3_BUCKET --> INCIDENT_FOLDER
    INCIDENT_FOLDER --> LOG_UPLOAD
    
    %% AI Analysis
    LOG_UPLOAD --> LAMBDA
    LAMBDA --> BEDROCK
    BEDROCK --> CLAUDE
    CLAUDE --> AI_ANALYSIS
    
    %% Report Generation
    AI_ANALYSIS --> INCIDENT_SUMMARY
    AI_ANALYSIS --> ROOT_CAUSE
    AI_ANALYSIS --> IMMEDIATE_FIXES
    AI_ANALYSIS --> PREVENTIVE_MEASURES
    AI_ANALYSIS --> LESSONS_LEARNED
    AI_ANALYSIS --> RECOMMENDATIONS
    
    classDef incident fill:#FF6B6B,stroke:#FF6B6B,stroke-width:2px,color:#fff
    classDef data fill:#00D4AA,stroke:#00D4AA,stroke-width:2px,color:#000
    classDef storage fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#000
    classDef ai fill:#8B5CF6,stroke:#8B5CF6,stroke-width:2px,color:#fff
    classDef report fill:#10B981,stroke:#10B981,stroke-width:2px,color:#fff
    
    class INCIDENT_DEMO,MEMORY_LEAK,CPU_STRESS,HEALTH_FAILURE incident
    class APP_LOGS,K8S_LOGS,METRICS,EVENTS,LOG_DIR,INCIDENT_ID,LOG_FILES data
    class S3_BUCKET,INCIDENT_FOLDER,LOG_UPLOAD storage
    class LAMBDA,BEDROCK,CLAUDE,AI_ANALYSIS ai
    class INCIDENT_SUMMARY,ROOT_CAUSE,IMMEDIATE_FIXES,PREVENTIVE_MEASURES,LESSONS_LEARNED,RECOMMENDATIONS report
```

---

## 🔄 Data Flow Architecture

```mermaid
graph LR
    subgraph "User Interaction"
        USER[User/Developer]
        GITHUB[GitHub Repository]
        LOCAL[Local Machine]
    end
    
    subgraph "Infrastructure Layer"
        TERRAFORM[Terraform]
        AWS[AWS Services]
        EKS[EKS Cluster]
    end
    
    subgraph "Application Layer"
        DOCKER[Docker]
        ECR[ECR Registry]
        K8S[Kubernetes]
        APP[Application]
    end
    
    subgraph "Monitoring Layer"
        PROMETHEUS[Prometheus]
        GRAFANA[Grafana]
        ALERTS[Alerts]
    end
    
    subgraph "AI Layer"
        LOGS[Logs]
        S3[S3 Storage]
        LAMBDA[Lambda]
        BEDROCK[Bedrock]
        RCA[RCA Report]
    end
    
    %% User Flow
    USER -->|Push Code| GITHUB
    USER -->|Deploy| LOCAL
    USER -->|Monitor| GRAFANA
    USER -->|Analyze| RCA
    
    %% Infrastructure Flow
    LOCAL -->|Terraform Apply| TERRAFORM
    TERRAFORM -->|Provision| AWS
    AWS -->|Create| EKS
    
    %% Application Flow
    LOCAL -->|Docker Build| DOCKER
    DOCKER -->|Push| ECR
    ECR -->|Pull| K8S
    K8S -->|Deploy| APP
    
    %% Monitoring Flow
    APP -->|Metrics| PROMETHEUS
    PROMETHEUS -->|Dashboards| GRAFANA
    PROMETHEUS -->|Alerts| ALERTS
    
    %% AI Analysis Flow
    APP -->|Logs| LOGS
    LOGS -->|Store| S3
    S3 -->|Retrieve| LAMBDA
    LAMBDA -->|Analyze| BEDROCK
    BEDROCK -->|Generate| RCA
    
    %% Feedback Loops
    ALERTS -->|Notify| USER
    RCA -->|Insights| USER
    GRAFANA -->|Visualize| USER
    
    classDef user fill:#6366F1,stroke:#6366F1,stroke-width:2px,color:#fff
    classDef infra fill:#7B42BC,stroke:#7B42BC,stroke-width:2px,color:#fff
    classDef app fill:#00D4AA,stroke:#00D4AA,stroke-width:2px,color:#000
    classDef monitoring fill:#F15922,stroke:#F15922,stroke-width:2px,color:#fff
    classDef ai fill:#8B5CF6,stroke:#8B5CF6,stroke-width:2px,color:#fff
    
    class USER,GITHUB,LOCAL user
    class TERRAFORM,AWS,EKS infra
    class DOCKER,ECR,K8S,APP app
    class PROMETHEUS,GRAFANA,ALERTS monitoring
    class LOGS,S3,LAMBDA,BEDROCK,RCA ai
```

---

## 📋 Architecture Summary

### **Key Components:**

1. **GitHub Repository**: Source code, CI/CD workflows, and configuration
2. **Local Development**: Docker builds, Terraform provisioning, kubectl management
3. **AWS Infrastructure**: VPC, EKS, ECR, S3, Lambda, Bedrock
4. **Kubernetes Resources**: Deployments, Services, HPA, Ingress
5. **Monitoring Stack**: Prometheus, Grafana, Alert Manager
6. **AI Incident Response**: Log capture, S3 storage, Lambda analysis, Bedrock RCA

### **Data Flow:**

1. **Code → Build → Deploy**: GitHub → Docker → ECR → Kubernetes
2. **Infrastructure**: Terraform → AWS → EKS → Monitoring
3. **Monitoring**: Application → Prometheus → Grafana → Alerts
4. **Incident Response**: Incident → Logs → S3 → Lambda → Bedrock → RCA

### **Key Benefits:**

- **Complete Automation**: From code push to production deployment
- **Comprehensive Monitoring**: Full-stack observability
- **AI-Powered Analysis**: Intelligent incident response
- **Scalable Architecture**: Production-ready design
- **Cost Optimization**: Efficient resource utilization

This architecture demonstrates a modern, cloud-native SRE environment with AI-enhanced incident response capabilities. 