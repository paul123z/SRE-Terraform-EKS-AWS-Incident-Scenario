# Bedrock Analysis Directory

This directory contains all files generated during AWS Bedrock incident analysis runs.

## 📁 File Structure

### Generated Files

When you run the Bedrock analysis script (`./scripts/analyze-incident-bedrock.sh`), the following files are created:

#### 1. Request Files
- **`bedrock_prompt_XXXXX.txt`** - The analysis prompt sent to Claude Sonnet 4
  - Contains the incident log data and analysis instructions
  - Uses a unique process ID (XXXXX) to avoid conflicts
  - Temporary file that gets cleaned up after analysis

- **`bedrock_payload_XXXXX.json`** - The complete JSON payload sent to AWS Bedrock
  - Includes the prompt, model configuration, and parameters
  - Uses the same process ID as the prompt file
  - Temporary file that gets cleaned up after analysis

#### 2. Response Files
- **`bedrock_response_XXXXX.json`** - Raw response from AWS Bedrock (Claude Sonnet 4)
  - Contains the complete AI analysis in JSON format
  - Includes metadata like model used, tokens consumed, etc.
  - **Persistent file** - kept for reference and debugging
  - Uses process ID to avoid overwriting previous analyses

- **`incident-analysis-{incident_id}.json`** - Structured analysis output
  - Clean, parsed version of the AI analysis
  - Contains incident summary, root cause analysis, fixes, etc.
  - **Persistent file** - main output for consumption
  - Named with the incident ID for easy identification

## 🔄 How It Works

### Analysis Process:
1. **Script Execution**: `./scripts/analyze-incident-bedrock.sh <incident_id>`
2. **Prompt Creation**: Incident logs are formatted into an analysis prompt
3. **Payload Generation**: Prompt is wrapped in proper Bedrock JSON format
4. **API Call**: Payload is sent to AWS Bedrock using the working CLI command
5. **Response Processing**: Raw response is parsed and structured
6. **File Generation**: All files are saved to this directory
7. **Cleanup**: Temporary files (prompt/payload) are removed

### File Lifecycle:
```
Temporary Files (cleaned up):
bedrock_prompt_XXXXX.txt → bedrock_payload_XXXXX.json → [API Call] → bedrock_response_XXXXX.json

Persistent Files (kept):
incident-analysis-{incident_id}.json (structured output)
bedrock_response_XXXXX.json (raw response)
```

## 📊 File Contents

### Example: `incident-analysis-demo-incident-20250806-205443.json`
```json
{
  "analysis": {
    "incident_summary": {
      "type": "Memory leak causing pod restart and HPA metrics failure",
      "severity": "MEDIUM",
      "duration": "Approximately 3 minutes",
      "affected_services": ["sre-demo-app", "horizontalpodautoscaler/sre-demo-app"]
    },
    "root_cause_analysis": {
      "primary_cause": "Memory leak simulation was enabled in the application",
      "contributing_factors": [...]
    },
    "immediate_fixes": [...],
    "preventive_measures": [...],
    "lessons_learned": [...],
    "recommendations": [...]
  }
}
```

### Example: `bedrock_response_XXXXX.json`
```json
{
  "id": "msg_bdrk_...",
  "type": "message",
  "role": "assistant",
  "model": "claude-sonnet-4-20250514",
  "content": [{"type": "text", "text": "```json\n{...}\n```"}],
  "usage": {"input_tokens": 2799, "output_tokens": 957}
}
```

## 🛠️ Usage

### View Analysis Results:
```bash
# View structured analysis
cat bedrock-analysis/incident-analysis-{incident_id}.json | jq

# View raw response
cat bedrock-analysis/bedrock_response_XXXXX.json | jq

# List all analyses
ls bedrock-analysis/incident-analysis-*.json
```

### Clean Up:
```bash
# Remove temporary files (if any remain)
rm bedrock-analysis/bedrock_*.txt bedrock-analysis/bedrock_payload_*.json

# Keep only structured analyses
ls bedrock-analysis/incident-analysis-*.json
```

### Integration:
```bash
# Use in scripts
ANALYSIS_FILE="bedrock-analysis/incident-analysis-$INCIDENT_ID.json"
if [ -f "$ANALYSIS_FILE" ]; then
    # Process analysis results
    jq -r '.analysis.incident_summary.type' "$ANALYSIS_FILE"
fi
```

## 🔍 Troubleshooting

### Common Issues:
1. **No files generated**: Check if Bedrock call succeeded
2. **Missing structured analysis**: Check JSON parsing in response
3. **Multiple response files**: Each run creates new files with unique IDs
4. **Large file sizes**: Raw responses can be several KB

### Debug Commands:
```bash
# Check if analysis was successful
ls -la bedrock-analysis/

# View latest response
ls -t bedrock-analysis/bedrock_response_*.json | head -1 | xargs cat | jq

# Check for parsing errors
cat bedrock-analysis/bedrock_response_*.json | jq -r '.content[0].text' | jq '.' 2>/dev/null || echo "JSON parsing failed"
```

## 📈 Benefits

### For Incident Analysis:
- **Persistent Results**: Analysis files are kept for reference
- **Structured Data**: Easy to parse and integrate with other tools
- **Debugging**: Raw responses help troubleshoot issues
- **Versioning**: Multiple analyses can be compared

### For Development:
- **Testing**: Can verify analysis quality
- **Debugging**: Raw responses show exactly what Bedrock returned
- **Integration**: Structured format enables automation
- **Documentation**: Files serve as examples and documentation

---

**Note**: This directory is created automatically when you run the Bedrock analysis. Files are organized by process ID to avoid conflicts during concurrent runs. 