✅ Phase 1: Infra with Terraform
✅ Set up backend config (e.g., S3 + DynamoDB for remote state)

✅ VPC, subnets (use AWS VPC module)

✅ EKS cluster (use official terraform-aws-eks module)

✅ Node group

✅ IAM roles for nodes & kubectl access

✅ Output kubeconfig

✅ Phase 2: Deploy App to EKS
✅ Write simple app manifests (or use an existing container)

✅ Apply with kubectl or Helm

✅ Expose via LoadBalancer or Ingress

✅ Phase 3: Add Monitoring (optional but adds wow-factor)
✅ Install Prometheus + Grafana via Helm

✅ Expose dashboards

✅ Add basic alerts (e.g., high CPU, pod crash loop)

✅ Phase 4: Simulate & Document Incident
✅ Option 1: Misconfigure liveness probe

✅ Option 2: Deploy app that crashes on load

✅ Option 3: Break a dependency (e.g., DNS issue)

✅ Create a script or CI step to simulate the issue

✅ Use logs, metrics, and kubectl to investigate

✅ Document root cause + resolution

✅ Phase 5: Declarative CI/CD
✅ GitHub Actions workflow:

✅ Plan & apply Terraform (optionally)

✅ Deploy app via kubectl apply or Helm

✅ Bonus: Trigger from PR

✅ Phase 6: Prepare for Presentation
✅ Create slides:

✅ Architecture overview

✅ Tools used

✅ Infra plan

✅ Incident scenario + timeline

✅ Resolution steps

✅ What you'd do better in a real prod environment

✅ Polish README with:

✅ Setup instructions

✅ CI/CD description

✅ Incident walkthrough

✅ Diagrams/screenshots