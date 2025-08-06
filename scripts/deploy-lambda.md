# deploy-lambda.sh

Deploys the incident-analyzer Lambda function that provides AI-powered incident analysis. Builds the Lambda package, uploads it to S3, and creates the Lambda function with proper IAM roles and environment variables. This was part of the original AI analysis approach before direct Bedrock integration. 