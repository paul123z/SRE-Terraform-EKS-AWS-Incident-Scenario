import json
import boto3
import os
from datetime import datetime, timedelta
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client('s3', region_name='eu-central-1')  # S3 in Frankfurt
# Use us-east-1 for Bedrock as it's available in N. Carolina
bedrock_client = boto3.client('bedrock-runtime', region_name='us-east-1')

def get_logs_from_s3(bucket_name, incident_id, time_range_minutes=30):
    """
    Retrieve logs from S3 for the specified incident and time range
    """
    try:
        # Calculate time range
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(minutes=time_range_minutes)
        
        # List objects in the incident folder
        prefix = f"incidents/{incident_id}/"
        response = s3_client.list_objects_v2(
            Bucket=bucket_name,
            Prefix=prefix
        )
        
        logs_content = []
        
        if 'Contents' in response:
            for obj in response['Contents']:
                # Get object content
                obj_response = s3_client.get_object(
                    Bucket=bucket_name,
                    Key=obj['Key']
                )
                content = obj_response['Body'].read().decode('utf-8')
                logs_content.append(f"File: {obj['Key']}\n{content}\n")
        
        return "\n".join(logs_content)
    
    except Exception as e:
        logger.error(f"Error retrieving logs from S3: {str(e)}")
        return f"Error retrieving logs: {str(e)}"

def analyze_with_bedrock(logs_content, incident_type="memory_leak"):
    """
    Use AWS Bedrock to analyze the logs and generate RCA
    Now uses the working AWS CLI method instead of boto3
    """
    try:
        logger.info("Using AWS CLI method for Bedrock (proven to work)")
        return analyze_with_bedrock_cli(logs_content, incident_type)
    
    except Exception as e:
        logger.error(f"AWS CLI Bedrock method failed: {str(e)}")
        # Fallback to basic analysis
        return generate_fallback_analysis(logs_content, incident_type, str(e))

def analyze_with_bedrock_cli(logs_content, incident_type="memory_leak"):
    """
    Use boto3 to call Bedrock directly (AWS CLI not available in Lambda environment)
    """
    try:
        logger.info("Using boto3 method for Bedrock (AWS CLI not available in Lambda)")
        
        # Create the analysis prompt
        analysis_prompt = f"""You are an expert SRE (Site Reliability Engineer) analyzing a Kubernetes incident. Please analyze the following incident log data and provide a comprehensive incident analysis report.

Please provide your analysis in the following JSON format:

{{
  "analysis": {{
    "incident_summary": {{
      "type": "string describing the incident type",
      "severity": "LOW|MEDIUM|HIGH|CRITICAL",
      "duration": "estimated duration of the incident",
      "affected_services": ["list of affected services"]
    }},
    "root_cause_analysis": {{
      "primary_cause": "string describing the primary root cause",
      "contributing_factors": ["list of contributing factors"]
    }},
    "immediate_fixes": [
      {{
        "priority": "HIGH|MEDIUM|LOW",
        "action": "string describing the action taken",
        "description": "string describing why this was done"
      }}
    ],
    "preventive_measures": [
      {{
        "measure": "string describing the preventive measure",
        "implementation": "string describing how to implement it",
        "timeline": "IMMEDIATE|SHORT_TERM|LONG_TERM"
      }}
    ],
    "lessons_learned": ["list of lessons learned from this incident"],
    "recommendations": [
      {{
        "category": "MONITORING|ALERTING|PROCESS|INFRASTRUCTURE",
        "recommendation": "string describing the recommendation",
        "impact": "HIGH|MEDIUM|LOW"
      }}
    ],
    "analysis_type": "bedrock_analysis"
  }}
}}

Focus on:
1. Identifying the root cause from the logs
2. Understanding the incident timeline
3. Analyzing the resolution actions taken
4. Providing actionable recommendations
5. Suggesting preventive measures

Be specific and actionable in your recommendations.

INCIDENT LOG DATA:
{logs_content[:8000]}  # Limit log size for Lambda"""

        # Create the Bedrock request payload
        payload = {
            "anthropic_version": "bedrock-2023-05-31",
            "messages": [
                {
                    "role": "user",
                    "content": analysis_prompt
                }
            ],
            "temperature": 0.3,
            "max_tokens": 2000
        }
        
        logger.info("Invoking Bedrock with boto3...")
        
        # Call Bedrock using boto3
        response = bedrock_client.invoke_model(
            modelId='us.anthropic.claude-sonnet-4-20250514-v1:0',
            body=json.dumps(payload)
        )
        
        logger.info("Bedrock response received")
        
        # Parse response
        response_body = json.loads(response['body'].read())
        
        # Extract the text content from the response
        if 'content' in response_body and len(response_body['content']) > 0:
            analysis_text = response_body['content'][0].get('text', '')
            
            # Try to extract JSON from the response
            try:
                # Find JSON in the response
                start_idx = analysis_text.find('{')
                end_idx = analysis_text.rfind('}') + 1
                if start_idx != -1 and end_idx != 0:
                    json_str = analysis_text[start_idx:end_idx]
                    return json.loads(json_str)
                else:
                    return {
                        "error": "Could not parse JSON from Bedrock response",
                        "raw_response": analysis_text
                    }
            except json.JSONDecodeError:
                return {
                    "error": "Invalid JSON in Bedrock response",
                    "raw_response": analysis_text
                }
        else:
            return {
                "error": "No content found in Bedrock response",
                "raw_response": response_body
            }
            
    except Exception as e:
        logger.error(f"Exception in boto3 method: {str(e)}")
        return {
            "error": f"Exception in boto3 method: {str(e)}"
        }

def generate_fallback_analysis(logs_content, incident_type="memory_leak", error_message=""):
    """
    Generate a basic analysis when Bedrock is not available
    """
    logger.info("Generating fallback analysis due to Bedrock access issues")
    
    # Basic analysis based on log content
    analysis = {
        "incident_summary": {
            "type": incident_type,
            "severity": "medium",
            "duration": "Unknown",
            "affected_services": ["sre-demo-app"]
        },
        "root_cause_analysis": {
            "primary_cause": "Demo incident simulation",
            "contributing_factors": [
                "Intentional memory leak simulation",
                "Demo environment testing"
            ],
            "timeline": {
                "detection_time": "During demo execution",
                "escalation_time": "Immediate",
                "resolution_time": "After demo completion"
            }
        },
        "immediate_fixes": [
            {
                "action": "Disable memory leak simulation",
                "priority": "high",
                "description": "Stop the intentional memory leak to restore normal operation"
            },
            {
                "action": "Restart application pods",
                "priority": "medium", 
                "description": "Clear any accumulated memory and restore clean state"
            }
        ],
        "preventive_measures": [
            {
                "measure": "Implement memory monitoring",
                "implementation": "Add memory usage alerts and monitoring",
                "timeline": "Immediate"
            },
            {
                "measure": "Resource limits",
                "implementation": "Set proper memory limits on containers",
                "timeline": "Next deployment"
            }
        ],
        "lessons_learned": [
            "Memory leaks can be simulated for testing",
            "Monitoring is crucial for early detection",
            "Demo environments should be isolated"
        ],
        "recommendations": [
            {
                "category": "monitoring",
                "recommendation": "Implement comprehensive memory monitoring",
                "impact": "high"
            },
            {
                "category": "infrastructure",
                "recommendation": "Set resource limits and requests",
                "impact": "medium"
            }
        ],
        "bedrock_status": f"Bedrock access failed: {error_message}",
        "analysis_type": "fallback"
    }
    
    return analysis

def handler(event, context):
    """
    Lambda function handler for incident analysis
    """
    try:
        # Get environment variables
        bucket_name = os.environ['S3_BUCKET']
        bedrock_model = os.environ.get('BEDROCK_MODEL', 'anthropic.claude-sonnet-4-20250514-v1:0:32k')
        
        # Parse event
        incident_id = event.get('incident_id', 'demo-incident')
        incident_type = event.get('incident_type', 'memory_leak')
        time_range_minutes = int(event.get('time_range_minutes', 30))
        
        logger.info(f"Event received: {event}")
        logger.info(f"Parsed parameters - incident_id: {incident_id}, incident_type: {incident_type}, time_range_minutes: {time_range_minutes}")
        
        logger.info(f"Starting analysis for incident: {incident_id}")
        
        # Get logs from S3
        logs_content = get_logs_from_s3(bucket_name, incident_id, time_range_minutes)
        
        if not logs_content or "Error retrieving logs" in logs_content:
            logger.warning("No logs found or error retrieving logs")
            logs_content = "No logs available for analysis. This might be a demo incident."
        
        # Return logs for local analysis (Bedrock analysis will be done locally)
        result = {
            "incident_id": incident_id,
            "analysis_timestamp": datetime.utcnow().isoformat(),
            "time_range_minutes": time_range_minutes,
            "logs_content": logs_content,
            "logs_size": len(logs_content),
            "status": "logs_retrieved"
        }
        
        logger.info(f"Analysis completed for incident: {incident_id}")
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(result, indent=2)
        }
    
    except Exception as e:
        logger.error(f"Lambda function error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': f'Internal server error: {str(e)}'
            })
        } 