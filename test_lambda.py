#!/usr/bin/env python3

import boto3
import json
import sys

def invoke_lambda():
    # Initialize AWS Lambda client
    lambda_client = boto3.client('lambda', region_name='eu-central-1')
    
    # Prepare payload
    payload = {
        "incident_id": "demo-incident-20250806-190142",
        "incident_type": "memory_leak",
        "time_range_minutes": 30
    }
    
    try:
        # Invoke Lambda function
        response = lambda_client.invoke(
            FunctionName='sre-incident-demo-incident-analyzer',
            Payload=json.dumps(payload)
        )
        
        # Parse response
        response_payload = json.loads(response['Payload'].read())
        
        print("Lambda invocation successful!")
        print("Response:")
        print(json.dumps(response_payload, indent=2))
        
        return True
        
    except Exception as e:
        print(f"Error invoking Lambda: {str(e)}")
        return False

if __name__ == "__main__":
    success = invoke_lambda()
    sys.exit(0 if success else 1) 