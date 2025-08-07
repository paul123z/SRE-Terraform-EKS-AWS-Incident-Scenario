# incident-demo.sh

**Purpose**: Simulates a realistic Kubernetes incident scenario for SRE training and demonstration.

**Key Features**:
- Creates memory leak simulation in running application
- Triggers pod restarts and HPA scaling issues
- Generates comprehensive incident logs in `/tmp/incident-logs/`
- Automatically uploads logs to S3 bucket for later analysis
- Integrates with AI analysis using `analyze-incident-bedrock.sh`
- Provides real-time incident response simulation

**Usage**: `./scripts/incident-demo.sh`

**Output**: Incident simulation logs, S3 upload confirmation, and AI analysis results

**Integration**: Works with both local analysis and GitHub workflow analysis 