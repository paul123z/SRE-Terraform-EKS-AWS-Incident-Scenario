# deploy.sh

Main deployment script that sets up the complete SRE incident demo infrastructure using Terraform. Creates EKS cluster, VPC, IAM roles, ECR repository, S3 bucket, and deploys the demo application with monitoring stack (Prometheus/Grafana). Includes validation steps to ensure all components are working correctly before completing deployment. 