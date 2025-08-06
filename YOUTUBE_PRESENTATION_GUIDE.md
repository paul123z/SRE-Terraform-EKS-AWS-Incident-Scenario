# YouTube Presentation Guide: SRE Incident Demo with AWS Bedrock Integration

## 🎬 Presentation Flow

### 1. Introduction (2-3 minutes)
- **Title**: "SRE Incident Response with AI: AWS Bedrock Integration"
- **Hook**: "What if you could have an AI expert analyze every incident automatically?"
- **Overview**: Complete SRE incident response with AI-powered analysis

### 2. Demo Overview (1 minute)
- Infrastructure as Code (Terraform)
- CI/CD Pipeline (GitHub Actions)
- Incident Detection & Resolution
- **NEW**: AI-Powered Analysis with AWS Bedrock

### 3. 🚨 CRITICAL SETUP: AWS Bedrock Provisioning (3-4 minutes)

**This is the most important step for the demo to work!**

#### What We Had to Do:
1. **Access AWS Bedrock Console**
   - Navigate to AWS Bedrock in your region
   - Go to "Base models" section

2. **Provision Claude Sonnet 4 Model**
   - Find "Claude Sonnet 4" under Anthropic provider
   - Click "Request model access" or "Provision model"
   - Accept the EULA (End User License Agreement)
   - Wait for provisioning (1-2 minutes)

3. **Verify Access Status**
   - Model should show "Access granted" with green checkmark
   - Status changes from "Not provisioned" to "Access granted"

#### Why This Matters:
- **Without provisioning**: You get "AccessDenied" or "ModelNotProvisioned" errors
- **With provisioning**: AI analysis works seamlessly
- **This was the key blocker** we had to solve

#### Show the Console:
- Display AWS Bedrock console
- Show "Base models (5)" with Anthropic section expanded
- Point out "Claude Sonnet 4" with "Access granted" status
- Emphasize the green checkmark

### 4. Demo Execution (8-10 minutes)

#### Phase 1: Infrastructure Setup
- Show Terraform deployment
- Point out EKS cluster, monitoring stack
- Mention that this creates the foundation

#### Phase 2: Incident Simulation
- Run the incident demo script
- Show memory leak simulation
- Demonstrate detection and resolution
- **Highlight**: Logs are captured for AI analysis

#### Phase 3: AI Analysis with Bedrock
- **Key Moment**: Run the Bedrock analysis
- Show the working Bedrock call
- Display the AI analysis results
- **Emphasize**: This works even after infrastructure is torn down

### 5. Technical Deep Dive (3-4 minutes)

#### The Working Bedrock Call:
```bash
aws bedrock-runtime invoke-model \
  --region us-west-1 \
  --cli-binary-format raw-in-base64-out \
  --model-id us.anthropic.claude-sonnet-4-20250514-v1:0 \
  --content-type application/json \
  --accept application/json \
  --body '{
    "anthropic_version": "bedrock-2023-05-31",
    "messages": [...]
  }' \
  response.json
```

#### What Makes It Work:
- **Correct model ID**: `us.anthropic.claude-sonnet-4-20250514-v1:0`
- **Proper JSON format**: `anthropic_version` required
- **Region consistency**: Same region where model is provisioned
- **File-based payload**: Avoids JSON escaping issues

### 6. Analysis Results (2-3 minutes)

#### Show the AI Output:
- **Incident Summary**: Type, severity, duration, affected services
- **Root Cause Analysis**: Primary cause and contributing factors
- **Immediate Fixes**: Priority-based action items
- **Preventive Measures**: Timeline-based recommendations
- **Lessons Learned**: Key takeaways
- **Recommendations**: Categorized by impact

### 7. Benefits & Impact (2-3 minutes)

#### For SRE Teams:
- **Faster MTTR**: AI analysis reduces manual investigation time
- **Consistent Analysis**: Standardized approach to incidents
- **Comprehensive Coverage**: All aspects of incident response
- **Offline Capability**: Works with just log files

#### For Organizations:
- **Reduced Costs**: Faster incident resolution
- **Better Learning**: Structured lessons learned
- **Improved Documentation**: Automated analysis reports
- **Scalable Process**: Can handle multiple incidents

### 8. Demo Files & Structure (1-2 minutes)

#### Show the File Structure:
```
bedrock-analysis/
├── bedrock_payload_XXXXX.json    # Request payload
├── bedrock_prompt_XXXXX.txt      # Analysis prompt
├── bedrock_response_XXXXX.json   # Raw AI response
└── incident-analysis-{id}.json   # Structured analysis
```

#### Key Scripts:
- `scripts/analyze-incident-bedrock.sh` - Main analysis script
- `scripts/incident-demo.sh` - Integrated demo
- `scripts/teardown.sh` - Cleanup (now handles S3 properly)

### 9. Troubleshooting Tips (1-2 minutes)

#### Common Issues:
1. **"AccessDenied"**: Model not provisioned
2. **"ModelNotProvisioned"**: Need to request access
3. **"ValidationException"**: JSON format issues
4. **"BucketNotEmpty"**: S3 cleanup needed

#### Solutions:
- Always provision models first
- Use file-based JSON payloads
- Check region consistency
- Run S3 cleanup before teardown

### 10. Conclusion (1-2 minutes)

#### Key Takeaways:
- **Provisioning is critical**: Must be done before using Bedrock
- **Integration works seamlessly**: Once setup is complete
- **Offline analysis capability**: Works with just log files
- **Comprehensive results**: Full incident analysis

#### Call to Action:
- Try the demo yourself
- Check out the GitHub repository
- Provision your own Bedrock models
- Integrate AI into your incident response

## 🎯 Presentation Tips

### Visual Elements:
- Show AWS Bedrock console screenshots
- Display the working vs. failing API calls
- Highlight the green "Access granted" checkmark
- Show before/after analysis results

### Key Messages:
- **"Provisioning is the key"** - Repeat this multiple times
- **"Works offline"** - Emphasize the log-based analysis
- **"Comprehensive analysis"** - Show the structured output
- **"Real-world integration"** - Demonstrate the complete workflow

### Demo Flow:
1. Start with the problem (manual incident analysis)
2. Show the solution (AI-powered analysis)
3. Highlight the critical step (model provisioning)
4. Demonstrate the working integration
5. Show the benefits and impact

## 📝 Script Notes

### Opening Hook:
"Imagine having an AI expert analyze every incident automatically, providing root cause analysis, immediate fixes, and preventive measures. That's exactly what we built with AWS Bedrock integration."

### Transition to Provisioning:
"Before we dive into the demo, there's one critical step that makes everything work: AWS Bedrock model provisioning. This was the key blocker we had to solve."

### Demo Conclusion:
"What we've shown today is a complete SRE incident response process enhanced with AI. The key insight is that proper model provisioning enables seamless AI integration that works even when infrastructure is down."

---

**Remember**: The provisioning step is the most important part to emphasize. Without it, the demo won't work! 