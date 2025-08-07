# incident-demo.sh

Complete SRE incident demonstration script that walks through a full incident lifecycle including simulation, detection, diagnosis, resolution, and verification. Now includes integrated AI analysis using AWS Bedrock as the final phase. Captures comprehensive logs and metrics throughout the incident for AI analysis, and automatically runs Bedrock analysis at the end to provide intelligent root cause analysis and recommendations.

## Overview

This script demonstrates a complete SRE incident response process with AI enhancement. It simulates a memory leak incident in a Kubernetes application, walks through the entire incident lifecycle, and concludes with AI-powered root cause analysis using AWS Bedrock.

## Demo Phases

### Phase 1: Setup and Preparation
- Validates Kubernetes cluster access
- Checks application deployment status
- **Disables HPA** to prevent automatic scaling during demo
- Prepares monitoring and logging infrastructure

### Phase 2: Incident Simulation (Memory Leak)
- **Manually triggers** memory leak simulation via API call
- Memory consumption grows from ~20MB to 1-1.5GB
- **Controlled simulation** - no automatic thresholds or self-healing

### Phase 3: Incident Detection
- Monitors memory usage growth via Grafana
- Checks application health endpoints
- Captures resource metrics and pod status
- Logs detection events for AI analysis

### Phase 4: Incident Diagnosis
- Analyzes application logs for root cause
- Identifies memory leak simulation as the trigger
- Captures diagnostic data for AI analysis

### Phase 5: Incident Resolution
- **Automatically disables** memory leak simulation via API call (script-controlled)
- Memory usage returns to normal (~20MB) when simulation stops
- Performs rolling restart of deployment
- Verifies application health restoration

### Phase 6: Verification
- Confirms application is healthy
- Validates memory usage is normal
- **Re-enables HPA** for normal operation
- Captures verification metrics

### Phase 7: AI-Powered Analysis
- Runs AWS Bedrock analysis on collected logs
- Provides intelligent RCA, recommendations, and lessons learned
- Displays structured analysis results

## Memory Leak Simulation Details

### How It Works
The memory leak is a **controlled simulation** within the application:

1. **Manual Trigger**: API call enables memory leak simulation
   ```bash
   curl -X POST http://$url/api/memory-leak \
       -H "Content-Type: application/json" \
       -d '{"enable": true}'
   ```

2. **Controlled Growth**: Memory consumption grows predictably (20MB → 1GB → 1.5GB)

3. **Automatic Disable**: Demo script automatically stops the simulation during resolution phase
   ```bash
   curl -X POST http://$url/api/memory-leak \
       -H "Content-Type: application/json" \
       -d '{"enable": false}'
   ```

4. **Memory Release**: Application releases allocated memory, returns to ~20MB

### Why This Design?
- **Predictable**: Exact control over incident timing
- **Safe**: No risk of real system instability
- **Educational**: Shows complete incident lifecycle from trigger to resolution
- **Repeatable**: Consistent results across multiple runs
- **Realistic**: Demonstrates proper incident response workflow (detect → diagnose → resolve → verify)

### HPA Behavior During Demo
- **Disabled**: HPA is set to `minReplicas: 1, maxReplicas: 1` during demo
- **No Auto-Scaling**: Prevents interference with memory leak simulation
- **Re-enabled**: HPA restored to normal operation after demo

## AI Analysis Workflow

### Log Collection
- **Local Storage**: Incident logs stored in `/tmp/incident-logs/`
- **Generated During Demo**: Logs captured throughout all phases
- **Persistent**: Available for analysis even after infrastructure cleanup

### AI Analysis Process
1. **Log Reading**: Script reads logs from `/tmp/incident-logs/incident-{incident_id}.log`
2. **Remote Analysis**: Communicates with AWS Bedrock in North Carolina region
3. **Local Storage**: Saves analysis results to `bedrock-analysis/` directory
4. **Structured Output**: Returns comprehensive analysis in JSON format

### Analysis Results Display
The demo automatically displays AI analysis results including:
- **Incident Summary**: Type, severity, duration, affected services
- **Root Cause Analysis**: Primary cause and contributing factors
- **Immediate Fixes**: Actions taken with priorities
- **Preventive Measures**: Long-term improvements with timelines
- **Lessons Learned**: Key takeaways from the incident
- **Recommendations**: Actionable suggestions by category

## File Locations

### Input Files
- **Incident Logs**: `/tmp/incident-logs/incident-{incident_id}.log`
- **Generated During**: Demo execution phases

### Output Files
- **AI Analysis**: `bedrock-analysis/bedrock_response_{pid}.json`
- **Analysis Prompts**: `bedrock-analysis/bedrock_prompt_{pid}.json`
- **Formatted Results**: `bedrock-analysis/bedrock_response_{pid}_formatted.json`

### Configuration
- **Bedrock Region**: us-west-1 (North Carolina)
- **Model**: us.anthropic.claude-sonnet-4-20250514-v1:0
- **Cross-Region**: Local logs + Remote Bedrock analysis

## Usage

```bash
# Run the complete demo
./scripts/incident-demo.sh

# The script will:
# 1. Set up the environment
# 2. Simulate memory leak incident
# 3. Walk through detection/diagnosis/resolution
# 4. Run AI analysis automatically
# 5. Display comprehensive results
```

## Key Features

- **Complete Lifecycle**: Full incident simulation from trigger to resolution
- **AI Enhancement**: Integrated AWS Bedrock analysis
- **Controlled Simulation**: Safe, predictable memory leak behavior
- **Cross-Region**: Local logs with remote AI analysis
- **Structured Output**: Comprehensive analysis with actionable recommendations
- **Educational**: Perfect for SRE training and demonstrations

## Technical Notes

- **Memory Limits**: Pod has 2Gi memory limit, simulation stays within bounds
- **No Auto-Healing**: Application doesn't self-disable memory leak
- **Script-Controlled Resolution**: Demo script automatically disables memory leak during resolution phase
- **Complete Workflow**: Demonstrates full incident response process (detect → diagnose → resolve → verify)
- **Offline Capable**: Analysis works with log files after infrastructure cleanup 