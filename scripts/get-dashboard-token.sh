#!/bin/bash

# Simple script to get Kubernetes Dashboard token

echo "🔑 Generating Kubernetes Dashboard token..."
echo ""

# Configuration
KUBECTL_CMD=$(command -v kubectl || echo "/usr/local/bin/kubectl")

# Generate token
TOKEN=$($KUBECTL_CMD -n kubernetes-dashboard create token dashboard-admin)

echo "✅ Token generated successfully!"
echo ""
echo "📋 Copy this token and paste it in the Kubernetes Dashboard:"
echo ""
echo "$TOKEN"
echo ""
echo "💡 Tip: This token will expire in about 1 hour"
echo "🔄 To get a new token, run this script again" 