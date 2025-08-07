# analyze-incident-bedrock.sh

Main script for AI-powered incident analysis using AWS Bedrock (Claude Sonnet 4). 

## Workflow
1. **Log Generation**: Incident logs are generated and stored in `/tmp/incident-logs/` while running `incident-demo.sh`
2. **Log Reading**: Script reads incident log files from local `/tmp/incident-logs/` directory
3. **Remote Analysis**: Communicates with AWS Bedrock in North Carolina region (us-west-1) for AI analysis
4. **Local Storage**: Saves prompt and response files to local `bedrock-analysis/` directory with unique process IDs

## Features
- **Cross-region**: Local logs + Remote Bedrock (North Carolina)
- **Offline Capable**: Works with log files even after infrastructure is torn down
- **Structured Output**: Returns comprehensive analysis including:
  - Root cause analysis
  - Immediate fixes
  - Preventive measures
  - Recommendations
- **Conflict Avoidance**: Uses unique process IDs to prevent file conflicts

## File Locations
- **Input Logs**: `/tmp/incident-logs/incident-{incident_id}.log`
- **Output Analysis**: `bedrock-analysis/` directory
- **Bedrock Region**: us-west-1 (North Carolina) 