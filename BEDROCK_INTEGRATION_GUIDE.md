# AWS Bedrock Integration Guide for SRE Incident Analysis

## Overview

This guide explains how to use AWS Bedrock (Claude Sonnet 4) for AI-powered incident analysis in the SRE Incident Demo. The integration allows you to analyze incident logs even after the infrastructure has been torn down, providing comprehensive root cause analysis and recommendations.

## 🚀 Key Features

- **Offline Analysis**: Works with log files even after infrastructure is destroyed
- **Comprehensive RCA**: Provides detailed root cause analysis, fixes, and recommendations
- **Structured Output**: Returns analysis in structured JSON format for easy parsing
- **Real-time Integration**: Seamlessly integrated into the incident demo workflow

## 📋 Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **AWS Bedrock access** enabled in your AWS account
3. **Claude Sonnet 4 model** provisioned and access granted in your region
4. **jq** installed for JSON parsing (optional but recommended)

## 🔐 AWS Bedrock Model Provisioning

**CRITICAL STEP**: Before using Bedrock, you must provision the Claude Sonnet 4 model and grant access.

### Step 1: Access AWS Bedrock Console
1. Go to AWS Bedrock Console in your region (e.g., us-west-1)
2. Navigate to "Base models" section
3. Look for "Anthropic" provider section

### Step 2: Provision Claude Sonnet 4
1. Find "Claude Sonnet 4" in the models list
2. Click on the model to view details
3. Click "Request model access" or "Provision model"
4. Accept the EULA (End User License Agreement)
5. Wait for provisioning to complete (usually takes 1-2 minutes)

### Step 3: Verify Access Status
- The model should show "Access granted" with a green checkmark
- Status should change from "Not provisioned" to "Access granted"
- You can now use the model via AWS CLI or SDK

### Step 4: Test Model Access
```bash
# Test if the model is accessible
aws bedrock list-foundation-models --region us-west-1 --query 'modelSummaries[?providerName==`Anthropic` && modelName==`Claude Sonnet 4`]'
```

**Note**: Without proper provisioning, you'll get "AccessDenied" or "ModelNotProvisioned" errors when trying to use Bedrock.

## 🔧 Setup

### 1. Verify AWS Bedrock Access

**Prerequisite**: Ensure Claude Sonnet 4 is provisioned (see AWS Bedrock Model Provisioning section above)

```bash
# Test the working Bedrock call
aws bedrock-runtime invoke-model \
  --region us-west-1 \
  --cli-binary-format raw-in-base64-out \
  --model-id us.anthropic.claude-sonnet-4-20250514-v1:0 \
  --content-type application/json \
  --accept application/json \
  --body '{
    "anthropic_version": "bedrock-2023-05-31",
    "messages": [
      {
        "role": "user",
        "content": "Hello, Claude!"
      }
    ],
    "temperature": 0.7,
    "max_tokens": 100
  }' \
  response.json
```

### 2. Check Available Scripts

```bash
# Make scripts executable
chmod +x scripts/analyze-incident-bedrock.sh
chmod +x scripts/test-bedrock-analysis.sh
```

## 🎯 Usage

### Option 1: Integrated with Incident Demo

The Bedrock analysis is now integrated into the main incident demo script:

```bash
# Run the complete incident demo (includes Bedrock analysis)
./scripts/incident-demo.sh
```

The demo will automatically:
1. Simulate an incident
2. Capture logs and metrics
3. Resolve the incident
4. **Run AI analysis using AWS Bedrock**

### Option 2: Standalone Analysis

Analyze existing incident logs independently:

```bash
# List available incident logs
ls /tmp/incident-logs/

# Analyze a specific incident
./scripts/analyze-incident-bedrock.sh incident-demo-incident-20250806-205443
```

### Option 3: Test Analysis

Test the Bedrock integration with available logs:

```bash
# Test with the most recent incident log
./scripts/test-bedrock-analysis.sh
```

## 📊 Analysis Output

The Bedrock analysis provides structured output including:

### Incident Summary
- **Type**: Description of the incident
- **Severity**: LOW/MEDIUM/HIGH/CRITICAL
- **Duration**: Estimated incident duration
- **Affected Services**: List of impacted services

### Root Cause Analysis
- **Primary Cause**: Main root cause identification
- **Contributing Factors**: Additional factors that contributed

### Immediate Fixes
- **Priority**: HIGH/MEDIUM/LOW
- **Action**: What was done to fix the issue
- **Description**: Why the action was taken

### Preventive Measures
- **Measure**: Description of preventive action
- **Implementation**: How to implement it
- **Timeline**: IMMEDIATE/SHORT_TERM/LONG_TERM

### Lessons Learned
- List of key takeaways from the incident

### Recommendations
- **Category**: MONITORING/ALERTING/PROCESS/INFRASTRUCTURE
- **Recommendation**: Specific recommendation
- **Impact**: HIGH/MEDIUM/LOW

## 🔍 Example Analysis

Here's what a typical Bedrock analysis looks like:

```
================================
AI-POWERED INCIDENT ANALYSIS WITH BEDROCK
================================

📊 INCIDENT SUMMARY
Type: Memory leak causing pod restart and HPA metrics failure | Severity: MEDIUM | Duration: Approximately 3 minutes

🔍 ROOT CAUSE ANALYSIS
Primary Cause: Memory leak simulation was enabled in the application, causing resource exhaustion and pod restart
• HPA unable to retrieve CPU and memory metrics from resource metrics API
• Missing or misconfigured metrics server
• Pod restart occurred due to memory pressure from the leak

⚡ IMMEDIATE FIXES
HIGH: Disabled memory leak simulation and restarted affected pods - Eliminated the root cause of memory consumption and restored service to healthy state

🛡️ PREVENTIVE MEASURES
Implement comprehensive memory monitoring and alerting: Set up Prometheus alerts for memory usage thresholds (IMMEDIATE)
Fix HPA metrics collection issues: Verify metrics-server deployment, ensure proper RBAC permissions (SHORT_TERM)

📚 LESSONS LEARNED
• HPA failure can mask underlying application issues and should be treated as a critical monitoring gap
• Memory leaks may not immediately manifest as application failures but can cause cascading issues

💡 RECOMMENDATIONS
MONITORING: Deploy and configure metrics-server properly to enable HPA functionality and resource monitoring (HIGH)
ALERTING: Create alerts for HPA failures, abnormal pod restart patterns, and memory usage anomalies (HIGH)
```

## 🛠️ Technical Details

### Script Location
- **Main Analysis Script**: `scripts/analyze-incident-bedrock.sh`
- **Test Script**: `scripts/test-bedrock-analysis.sh`
- **Integration**: Updated `scripts/incident-demo.sh`

### Configuration
- **AWS Region**: `us-west-1` (configurable)
- **Bedrock Model**: `us.anthropic.claude-sonnet-4-20250514-v1:0`
- **Log Directory**: `/tmp/incident-logs/`
- **Output Format**: JSON with structured analysis

### File Structure
```
/tmp/incident-logs/
├── incident-demo-incident-20250806-190142.log
├── incident-demo-incident-20250806-193619.log
├── incident-demo-incident-20250806-194919.log
└── incident-demo-incident-20250806-205443.log

/tmp/
├── bedrock_response.json          # Raw Bedrock response
└── incident-analysis-{id}.json    # Structured analysis output
```

## 🔧 Troubleshooting

### Common Issues

1. **AWS Credentials Not Configured**
   ```bash
   aws configure
   ```

2. **Bedrock Access Denied**
   - Ensure Bedrock is enabled in your AWS account
   - Verify Claude Sonnet 4 model is available in your region
   - Check IAM permissions for Bedrock access

3. **Log Files Not Found**
   ```bash
   # Check if logs exist
   ls -la /tmp/incident-logs/
   
   # Run incident demo to generate logs
   ./scripts/incident-demo.sh
   ```

4. **JSON Parsing Errors**
   ```bash
   # Install jq if not available
   sudo apt-get install jq  # Ubuntu/Debian
   brew install jq          # macOS
   ```

### Debug Mode

To see detailed debugging information:

```bash
# Set debug mode
export DEBUG=1
./scripts/analyze-incident-bedrock.sh <incident_id>
```

## 🎯 Benefits

### For SRE Teams
- **Faster Incident Resolution**: AI-powered analysis reduces manual investigation time
- **Consistent Analysis**: Standardized approach to incident analysis
- **Comprehensive Coverage**: Covers root cause, fixes, and preventive measures
- **Offline Capability**: Works even when infrastructure is down

### For Organizations
- **Reduced MTTR**: Faster mean time to resolution
- **Improved Learning**: Structured lessons learned and recommendations
- **Better Documentation**: Automated incident analysis documentation
- **Cost Effective**: Uses existing AWS infrastructure

## 🔄 Integration with Existing Workflows

### CI/CD Integration
The Bedrock analysis can be integrated into CI/CD pipelines:

```bash
# Example: Analyze incident logs in CI/CD
if [ -f "/tmp/incident-logs/incident-$INCIDENT_ID.log" ]; then
    ./scripts/analyze-incident-bedrock.sh "$INCIDENT_ID"
    # Upload analysis results to monitoring system
    aws s3 cp "/tmp/incident-analysis-$INCIDENT_ID.json" "s3://incident-analysis-bucket/"
fi
```

### Monitoring Integration
Connect analysis results to monitoring systems:

```bash
# Example: Send analysis to Slack
ANALYSIS=$(cat "/tmp/incident-analysis-$INCIDENT_ID.json")
curl -X POST -H 'Content-type: application/json' \
  --data "{\"text\":\"Incident Analysis: $ANALYSIS\"}" \
  $SLACK_WEBHOOK_URL
```

## 📈 Future Enhancements

Potential improvements for the Bedrock integration:

1. **Multi-Model Support**: Support for different Bedrock models
2. **Custom Prompts**: Allow customization of analysis prompts
3. **Historical Analysis**: Compare incidents across time
4. **Integration APIs**: REST API for programmatic access
5. **Dashboard Integration**: Web-based analysis dashboard

## 🤝 Contributing

To contribute to the Bedrock integration:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📞 Support

For issues or questions:

1. Check the troubleshooting section above
2. Review the script logs for error messages
3. Verify AWS Bedrock configuration
4. Test with the provided example scripts

---

**You're now Claude-powered for incident engineering! 🚀** 