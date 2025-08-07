# GitHub Actions: S3 Log Analysis with Bedrock

## Overview
This GitHub Actions workflow provides a manual way to analyze S3 log files using AWS Bedrock (Claude Sonnet 4) for AI-powered incident analysis.

## How to Use

### 1. Prerequisites
- AWS credentials configured in GitHub Secrets:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
- AWS Bedrock access enabled
- S3 bucket with log files

### 2. Running the Workflow

#### Manual Trigger
1. Go to your GitHub repository
2. Click on "Actions" tab
3. Select "Analyze S3 Logs with Bedrock" workflow
4. Click "Run workflow"
5. Fill in the parameters:
   - **S3 Object URL**: The URL to your log file
   - **Incident Type**: Type of incident (optional)

#### Supported URL Formats
- **S3 URI**: `s3://bucket-name/path/to/log.log`
- **HTTPS URL**: `https://bucket-name.s3.region.amazonaws.com/path/to/log.log`

### 3. Example URLs

Based on your S3 bucket structure:
```
https://sre-incident-demo-incident-logs-l35a3g7s.s3.eu-central-1.amazonaws.com/incidents/demo-incident-20250807-222634/incident-demo-incident-20250807-222634.log
```

Or using S3 URI:
```
s3://sre-incident-demo-incident-logs-l35a3g7s/incidents/demo-incident-20250807-222634/incident-demo-incident-20250807-222634.log
```

## What the Workflow Does

### 1. Setup Phase
- Installs AWS CLI v2
- Configures AWS credentials
- Verifies Bedrock access

### 2. Log Retrieval
- Parses the S3 URL to extract bucket and key
- Downloads the log file from S3
- Shows log file preview

### 3. AI Analysis
- Creates an analysis prompt for Bedrock
- Calls AWS Bedrock (Claude Sonnet 4)
- Parses the AI response

### 4. Results Display
- Shows structured analysis in the GitHub Actions console
- Includes:
  - Incident summary (type, severity, duration)
  - Root cause analysis
  - Immediate fixes
  - Recommendations
  - Lessons learned

### 5. Artifacts
- Uploads analysis results as artifacts
- Includes the original log file and Bedrock response
- Available for download for 7 days

## Output Example

```
🤖 AI-POWERED INCIDENT ANALYSIS

[INFO] Analyzing log file: ./incident-log.log
[INFO] Incident type: memory_leak
[INFO] Bedrock model: us.anthropic.claude-sonnet-4-20250514-v1:0
[INFO] AWS region: us-west-1

[INFO] Log content loaded (size: 19181 characters)
[INFO] Invoking AWS Bedrock for analysis...
[SUCCESS] Bedrock analysis completed successfully!

📊 INCIDENT ANALYSIS RESULTS

INCIDENT SUMMARY:
  Type: Memory leak simulation incident with HPA scaling issues
  Severity: MEDIUM
  Duration: Approximately 2 minutes (20:26:55 - 20:28:08)

ROOT CAUSE ANALYSIS:
  Primary Cause: Memory leak simulation was enabled in the application via API call

IMMEDIATE FIX: HIGH - Disabled memory leak simulation via application API
IMMEDIATE FIX: HIGH - Restarted affected pods to clear memory state

RECOMMENDATION (MONITORING): Deploy and configure metrics-server properly (Impact: HIGH)
RECOMMENDATION (ALERTING): Create alerts for HPA scaling failures (Impact: HIGH)
RECOMMENDATION (INFRASTRUCTURE): Set appropriate resource requests and limits (Impact: MEDIUM)

LESSON: HPA cannot function properly without reliable metrics from the resource metrics API
LESSON: Memory leaks can be quickly identified and resolved when proper monitoring is in place

✅ Analysis completed successfully!
```

## Configuration

### AWS Credentials
Add these secrets to your GitHub repository:
1. Go to Settings → Secrets and variables → Actions
2. Add repository secrets:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key

### Required AWS Permissions
The AWS credentials need:
- S3 read access to the bucket
- Bedrock invoke access for the Claude model

### IAM Policy Example
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::your-bucket-name/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "bedrock:InvokeModel"
            ],
            "Resource": "arn:aws:bedrock:us-west-1::foundation-model/us.anthropic.claude-sonnet-4-20250514-v1:0"
        }
    ]
}
```

## Troubleshooting

### Common Issues

1. **Invalid S3 URL Format**
   - Use the exact format: `https://bucket.s3.region.amazonaws.com/key`
   - Or S3 URI: `s3://bucket/key`

2. **AWS Credentials Error**
   - Verify secrets are set correctly
   - Check AWS permissions

3. **Bedrock Access Denied**
   - Ensure Bedrock is enabled in your AWS account
   - Verify model access in AWS console

4. **Log File Not Found**
   - Check the S3 URL is correct
   - Verify the file exists in S3

### Debug Information
The workflow provides detailed logging:
- AWS CLI version
- Bedrock model availability
- S3 download status
- Analysis progress

## Integration with Your Workflow

This workflow can be integrated with your existing CI/CD pipeline:

1. **After Incident Demo**: Automatically analyze logs
2. **Manual Analysis**: On-demand analysis of specific incidents
3. **Scheduled Analysis**: Regular analysis of new logs

## Benefits

- **No Local Setup**: Runs in GitHub Actions environment
- **Consistent Analysis**: Same AI model and prompt every time
- **Structured Output**: JSON-formatted results
- **Artifact Storage**: Results saved for later review
- **Cross-Platform**: Works from any device with web access
