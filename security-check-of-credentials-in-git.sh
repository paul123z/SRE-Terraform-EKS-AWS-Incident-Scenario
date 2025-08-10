#!/bin/bash

# Quick Security Check for Git Credentials
# This script runs Gitleaks to scan for secrets in the repository

set -e

echo "🔍 Running Gitleaks security scan..."
echo "===================================="

# Check if gitleaks is installed
if ! command -v gitleaks &> /dev/null; then
    echo "❌ Error: Gitleaks is not installed"
    echo "Install with: curl -sSfL https://raw.githubusercontent.com/gitleaks/gitleaks/master/scripts/install.sh | sh"
    exit 1
fi

# Run gitleaks scan
echo "Scanning current files AND Git history for secrets..."
echo

if gitleaks detect --source . --log-opts="--all" --verbose; then
    echo
    echo "✅ No secrets found in repository!"
    echo "🛡️  Your repository is secure."
else
    echo
    echo "⚠️  Potential secrets detected!"
    echo "📋 Review the findings above and take appropriate action."
    echo "💡 Remember: Some findings might be false positives."
    exit 1
fi

echo
echo "🔍 Scan completed successfully!"
