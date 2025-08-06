import json
import boto3
import os
from datetime import datetime, timedelta
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client('s3')
# Use us-west-1 for Bedrock as it's available there
bedrock_client = boto3.client('bedrock-runtime', region_name='us-west-1')

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
    """
    try:
        # Prepare the prompt for Bedrock
        prompt = f"""
You are an expert SRE (Site Reliability Engineer) performing Root Cause Analysis (RCA) on a production incident.

INCIDENT TYPE: {incident_type.upper()}

LOGS TO ANALYZE:
{logs_content}

Please provide a comprehensive RCA analysis in the following JSON format:

{{
    "incident_summary": {{
        "type": "string",
        "severity": "high|medium|low",
        "duration": "string",
        "affected_services": ["array of service names"]
    }},
    "root_cause_analysis": {{
        "primary_cause": "string",
        "contributing_factors": ["array of contributing factors"],
        "timeline": {{
            "detection_time": "string",
            "escalation_time": "string",
            "resolution_time": "string"
        }}
    }},
    "immediate_fixes": [
        {{
            "action": "string",
            "priority": "high|medium|low",
            "description": "string"
        }}
    ],
    "preventive_measures": [
        {{
            "measure": "string",
            "implementation": "string",
            "timeline": "string"
        }}
    ],
    "lessons_learned": [
        "array of lessons learned"
    ],
    "recommendations": [
        {{
            "category": "monitoring|infrastructure|process|code",
            "recommendation": "string",
            "impact": "high|medium|low"
        }}
    ]
}}

Focus on:
1. What caused the issue most likely
2. How to fix it immediately
3. How to prevent it in the future
4. Specific actionable recommendations

Be concise but thorough. If logs are insufficient, note what additional information would be needed.
"""

        # Call Bedrock
        response = bedrock_client.invoke_model(
            modelId='anthropic.claude-3-sonnet-20240229-v1:0',
            body=json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 4000,
                "messages": [
                    {
                        "role": "user",
                        "content": prompt
                    }
                ]
            })
        )
        
        # Parse response
        response_body = json.loads(response['body'].read())
        analysis = response_body['content'][0]['text']
        
        # Try to extract JSON from the response
        try:
            # Find JSON in the response
            start_idx = analysis.find('{')
            end_idx = analysis.rfind('}') + 1
            if start_idx != -1 and end_idx != 0:
                json_str = analysis[start_idx:end_idx]
                return json.loads(json_str)
            else:
                return {
                    "error": "Could not parse JSON from Bedrock response",
                    "raw_response": analysis
                }
        except json.JSONDecodeError:
            return {
                "error": "Invalid JSON in Bedrock response",
                "raw_response": analysis
            }
    
    except Exception as e:
        logger.error(f"Error calling Bedrock: {str(e)}")
        # Fallback to basic analysis when Bedrock is not available
        return generate_fallback_analysis(logs_content, incident_type, str(e))

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
        time_range_minutes = event.get('time_range_minutes', 30)
        
        logger.info(f"Starting analysis for incident: {incident_id}")
        
        # Get logs from S3
        logs_content = get_logs_from_s3(bucket_name, incident_id, time_range_minutes)
        
        if not logs_content or "Error retrieving logs" in logs_content:
            logger.warning("No logs found or error retrieving logs")
            logs_content = "No logs available for analysis. This might be a demo incident."
        
        # Analyze with Bedrock
        analysis_result = analyze_with_bedrock(logs_content, incident_type)
        
        # Add metadata
        result = {
            "incident_id": incident_id,
            "analysis_timestamp": datetime.utcnow().isoformat(),
            "time_range_minutes": time_range_minutes,
            "bedrock_model": bedrock_model,
            "analysis": analysis_result
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