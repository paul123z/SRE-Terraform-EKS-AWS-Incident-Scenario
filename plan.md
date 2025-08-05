 High-Level Architecture
Infrastructure (provisioned via Terraform):

VPC, Subnets

EKS Cluster

Node Group(s)

IAM Roles

Security Groups

Application Deployment:

Sample app (e.g., Nginx or Node.js service)

Kubernetes manifests (Deployment, Service, Ingress)

Observability Stack (optional but impactful):

Prometheus & Grafana (via Helm)

FluentBit for logs (or AWS CloudWatch)

Alertmanager or CloudWatch Alarms

CI/CD Pipeline:

GitHub Actions (or another engine)

Declarative deploy of app + Helm charts (optional: ArgoCD)

Incident Simulation:

Broken image, misconfigured liveness/readiness probe, CPU spike, or memory leak

Incident Walkthrough:

Detection (alerts/logs)

Diagnosis (kubectl, logs, metrics)

Resolution (rollback, fix config, scale, etc.)