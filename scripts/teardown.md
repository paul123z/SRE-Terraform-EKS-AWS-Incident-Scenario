# teardown.sh

**Purpose**: Safely removes all AWS infrastructure and resources created by the deployment.

**Key Features**:
- Destroys EKS cluster and all Kubernetes resources
- Removes ECR repositories and Docker images
- Cleans up S3 bucket contents (including versioned objects)
- Terminates VPC, subnets, and networking components
- Removes IAM roles and policies
- Provides cleanup verification and status reporting

**Usage**: `./scripts/teardown.sh`

**Safety**: Includes confirmation prompts and graceful error handling

**Output**: Complete cleanup status and resource removal confirmation 