Here’s a clear, copy-paste–ready guide for your team (or Cursor AI agent) that explains how to:

✅ Call Amazon Bedrock (Claude Sonnet 4) using the working shell script

⚙️ Integrate it into incident analysis tooling

🧪 Demo it with a practical use case

🧠 Understand and summarize what went wrong previously

🧭 Guide: Using Claude Sonnet 4 via Amazon Bedrock in Incident Analysis (for Cursor)
✅ 1. Working Bedrock Script for Claude Sonnet 4
This shell script successfully calls Claude Sonnet 4 through Amazon Bedrock using a system-managed inference profile:

bash
Copy
Edit
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
        "content": "Explain Kubernetes like I am five."
      }
    ],
    "temperature": 0.7,
    "max_tokens": 500
  }' \
  response.json
✅ To view the response:
bash
Copy
Edit
cat response.json | jq
Or just:

bash
Copy
Edit
cat response.json
🔍 2. How to Use Bedrock in Incident Analysis
Goal:
Leverage Claude Sonnet 4 (via Bedrock) to summarize, explain, or recommend actions during or after incidents.

Example: Provide Bedrock the following message:
json
Copy
Edit
{
  "messages": [
    {
      "role": "user",
      "content": "Analyze the following Kubernetes incident logs and explain the root cause: [paste logs here]"
    }
  ]
}
Then call the same aws bedrock-runtime invoke-model command, replacing the content value dynamically with your actual incident summary, logs, or timeline.

🚨 3. Demo Use Case: Incident Timeline Explanation
Prompt:
json
Copy
Edit
"content": "A pod in namespace `payments` was OOMKilled at 10:02 UTC after a spike in memory usage. HPA had not been configured. Explain the likely root cause and how to prevent it."
Claude Response Example:
"The pod was terminated due to out-of-memory (OOM) errors. This likely happened because the application consumed more memory than the container limit allowed. Without a Horizontal Pod Autoscaler (HPA) or memory limit alerts, the spike went unnoticed until termination..."

🧠 4. What Went Wrong Before (Explained for Cursor or Engineers)
❌ Attempted solutions that failed:
Passing the provisioned_model_arn directly via --model-arn or boto3 → not supported

Adding "resourceArn" or "configuration" blocks into JSON → rejected by Bedrock

Using inference_profile_arn in boto3 or body → not recognized

Trying invoke_model_with_response_stream or inferenceConfig → not valid SDK params

✅ What finally worked:
Calling the model via aws bedrock-runtime invoke-model

Model ID: us.anthropic.claude-sonnet-4-20250514-v1:0

anthropic_version required

Using system-managed inference profile without explicitly referencing it in the payload or API

Response successfully returned to response.json

✅ 5. Cursor Integration Ideas
Use Claude Sonnet 4 via Bedrock to:

📖 Explain complex logs or traces

🧠 Summarize alert groups or Grafana metrics

🛠 Recommend mitigations during PagerDuty escalations

Automate this inside Cursor with:

A command like !analyze-incident.sh to pass logs to Claude

Cursor agent pre-configured with prompt templates and token guards

Let me know if you want this turned into:

A Markdown doc for GitHub

A CLI tool wrapper (like analyze-with-bedrock "...")

Or a Python service for integrating with CI/CD or incident bots

You're now Claude-powered for incident engineering. 🚀