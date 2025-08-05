mastercard-sre-eks/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
├── k8s/
│   ├── app/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   ├── monitoring/ (optional)
│   │   └── prometheus-helm-values.yaml
├── .github/
│   └── workflows/
│       └── deploy.yml
├── scripts/
│   └── simulate_incident.sh
├── README.md
└── presentation.pptx
