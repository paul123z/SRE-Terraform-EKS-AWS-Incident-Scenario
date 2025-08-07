# Lambda S3 Analysis Architecture

## Overview
This document explains the hybrid architecture for AI-powered incident analysis that combines AWS Lambda for S3 log retrieval with local bash scripts for Bedrock communication.

## Why This Architecture?

### The Problem
- **boto3 + Bedrock**: Has compatibility issues in Lambda environment
- **AWS CLI in Lambda**: Not available by default, requires complex layers
- **Local AWS CLI + Bedrock**: Works perfectly but needs logs from S3

### The Solution
**Hybrid Approach**: Use Lambda for what it's good at (S3 access), use local scripts for what works (Bedrock via AWS CLI).

## Architecture Flow

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Local Script  │───▶│  Lambda Function│───▶│   S3 Bucket     │
│                 │    │                 │    │                 │
│ invoke-lambda-  │    │ incident-       │    │ incident-logs/  │
│ s3-analysis.sh  │    │ analyzer.py     │    │ incident-*.log  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Local Logs    │    │   Lambda Logs   │    │   S3 Logs       │
│                 │    │                 │    │                 │
│ /tmp/incident-  │    │ CloudWatch      │    │ Frankfurt       │
│ logs/           │    │ Logs            │    │ Region          │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │
         ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Bedrock Script │───▶│   AWS Bedrock   │───▶│   Analysis      │
│                 │    │                 │    │                 │
│ analyze-incident│    │ Claude Sonnet 4 │    │ Results saved   │
│ -bedrock.sh     │    │ N. Carolina     │    │ locally         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Detailed Flow

### 1. Local Script Execution
```bash
./lambda/invoke-lambda-s3-analysis.sh demo-incident-20250807-222634 30
```

### 2. Lambda Function (S3 Log Retrieval)
- **Function**: `sre-incident-demo-incident-analyzer`
- **Region**: `eu-central-1` (Frankfurt)
- **Purpose**: Retrieve logs from S3 bucket
- **Input**: `{"incident_id": "...", "time_range_minutes": 30}`
- **Output**: `{"logs_content": "...", "logs_size": 12345}`

### 3. S3 Bucket
- **Bucket**: `sre-incident-demo-incident-logs-l35a3g7s`
- **Region**: `eu-central-1` (Frankfurt)
- **Structure**: `incidents/{incident_id}/logs/`

### 4. Local Bedrock Analysis
- **Script**: `./scripts/analyze-incident-bedrock.sh`
- **Method**: AWS CLI (proven to work)
- **Region**: `us-west-1` (N. Carolina)
- **Model**: `us.anthropic.claude-sonnet-4-20250514-v1:0`

### 5. Results Storage
- **Location**: `lambda-results-from-s3-bedrock/`
- **Files**:
  - `raw-response-{incident_id}-{timestamp}.json` - Lambda response
  - `logs-{incident_id}-{timestamp}.log` - Retrieved logs
  - `analysis-{incident_id}-{timestamp}.json` - Bedrock analysis
  - `summary-{incident_id}-{timestamp}.txt` - Human-readable summary

## Fallback Mechanism

If Lambda fails, the script automatically falls back to local logs:

```bash
# Check local logs first
LOCAL_LOG_FILE="/tmp/incident-logs/incident-$INCIDENT_ID.log"
if [ -f "$LOCAL_LOG_FILE" ]; then
    # Use local logs instead of Lambda
fi
```

## Key Benefits

1. **Reliability**: Uses proven working methods for each component
2. **Flexibility**: Can work with S3 logs or local logs
3. **Cross-region**: Lambda in Frankfurt, Bedrock in N. Carolina
4. **Local Results**: All analysis results saved locally for easy access
5. **Fault Tolerance**: Graceful fallback if Lambda fails

## File Structure

```
lambda/
├── incident-analyzer.py          # Lambda function (S3 log retrieval only)
├── invoke-lambda-s3-analysis.sh  # Main orchestration script
└── lambda-analysis-architecture.md # This documentation

lambda-results-from-s3-bedrock/
├── raw-response-*.json           # Lambda responses
├── logs-*.log                    # Retrieved logs
├── analysis-*.json               # Bedrock analysis results
└── summary-*.txt                 # Human-readable summaries
```

## Usage

```bash
# Basic usage
./lambda/invoke-lambda-s3-analysis.sh <incident_id> [time_range_minutes]

# Example
./lambda/invoke-lambda-s3-analysis.sh demo-incident-20250807-222634 30
```

## Troubleshooting

### Lambda Invocation Fails
- Check Lambda function exists: `aws lambda get-function --function-name sre-incident-demo-incident-analyzer`
- Check S3 bucket access
- Script will fallback to local logs automatically

### Bedrock Analysis Fails
- Check AWS CLI is installed: `aws --version`
- Check Bedrock access: `aws bedrock list-foundation-models --region us-west-1`
- Check model access in AWS console

### No Results Generated
- Ensure incident demo was run first to generate logs
- Check `/tmp/incident-logs/` for local log files
- Verify `bedrock-analysis/` directory exists

## Why Not LangChain?

LangChain would face the same boto3 compatibility issues in the Lambda environment. The local AWS CLI approach is:
- **Proven to work** (you've tested it)
- **Simpler** (no additional dependencies)
- **More reliable** (direct AWS CLI calls)
- **Easier to debug** (standard shell commands)
