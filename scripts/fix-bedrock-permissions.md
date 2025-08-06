# fix-bedrock-permissions.sh

Adds the missing Bedrock permissions to the Lambda role so it can access AWS Bedrock in us-west-1. This script fixes the "AccessDeniedException" error by adding the required IAM policy. 