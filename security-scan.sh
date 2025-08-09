#!/bin/bash

# Security Scanning Script for Git Repository
# This script uses multiple tools to scan for secrets and sensitive information

set -e

echo "🔍 Starting comprehensive security scan..."
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create results directory
mkdir -p security-scan-results
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

echo -e "${YELLOW}📅 Scan timestamp: $TIMESTAMP${NC}"
echo

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 1. GITLEAKS SCAN
echo -e "${YELLOW}🔍 Running Gitleaks scan...${NC}"
if command_exists gitleaks; then
    echo "Scanning current files and Git history for secrets..."
    if gitleaks detect --source . --verbose --report-format json --report-path "security-scan-results/gitleaks-$TIMESTAMP.json" --exit-code 0; then
        echo -e "${GREEN}✅ Gitleaks scan completed${NC}"
        
        # Count findings
        if [ -f "security-scan-results/gitleaks-$TIMESTAMP.json" ]; then
            GITLEAKS_COUNT=$(jq length "security-scan-results/gitleaks-$TIMESTAMP.json" 2>/dev/null || echo "0")
            if [ "$GITLEAKS_COUNT" -gt 0 ]; then
                echo -e "${RED}⚠️  Found $GITLEAKS_COUNT potential secrets with Gitleaks${NC}"
            else
                echo -e "${GREEN}✅ No secrets found with Gitleaks${NC}"
            fi
        fi
    else
        echo -e "${RED}❌ Gitleaks scan failed${NC}"
    fi
    echo
else
    echo -e "${RED}❌ Gitleaks not installed${NC}"
    echo "Install with: curl -sSfL https://raw.githubusercontent.com/gitleaks/gitleaks/master/scripts/install.sh | sh"
    echo
fi

# 2. TRUFFLEHOG SCAN
echo -e "${YELLOW}🔍 Running TruffleHog scan...${NC}"
if command_exists trufflehog3; then
    echo "Scanning Git history for high-entropy strings and secrets..."
    trufflehog3 --format json --output "security-scan-results/trufflehog-$TIMESTAMP.json" . || true
    echo -e "${GREEN}✅ TruffleHog scan completed${NC}"
    
    # Count findings
    if [ -f "security-scan-results/trufflehog-$TIMESTAMP.json" ]; then
        TRUFFLEHOG_COUNT=$(jq length "security-scan-results/trufflehog-$TIMESTAMP.json" 2>/dev/null || echo "0")
        if [ "$TRUFFLEHOG_COUNT" -gt 0 ]; then
            echo -e "${RED}⚠️  Found $TRUFFLEHOG_COUNT potential secrets with TruffleHog${NC}"
        else
            echo -e "${GREEN}✅ No secrets found with TruffleHog${NC}"
        fi
    fi
    echo
else
    echo -e "${RED}❌ TruffleHog not installed${NC}"
    echo "Install with: pip3 install truffleHog3"
    echo
fi

# 3. CUSTOM PATTERN SEARCH
echo -e "${YELLOW}🔍 Running custom pattern search...${NC}"
echo "Searching for common secret patterns..."

# Create custom patterns file
cat > "security-scan-results/custom-patterns-$TIMESTAMP.txt" << 'EOF'
=== AWS Keys ===
EOF

# Search for AWS patterns
grep -r -i --exclude-dir=.git --exclude-dir=node_modules --exclude="*.json" --exclude="security-scan.sh" \
    -E "(AKIA|ASIA)[A-Z0-9]{16}" . >> "security-scan-results/custom-patterns-$TIMESTAMP.txt" 2>/dev/null || true

echo >> "security-scan-results/custom-patterns-$TIMESTAMP.txt"
echo "=== API Keys ===" >> "security-scan-results/custom-patterns-$TIMESTAMP.txt"

# Search for common API key patterns
grep -r -i --exclude-dir=.git --exclude-dir=node_modules --exclude="*.json" --exclude="security-scan.sh" \
    -E "(api_key|apikey|api-key|secret_key|secretkey|secret-key|access_key|accesskey|access-key)" . >> "security-scan-results/custom-patterns-$TIMESTAMP.txt" 2>/dev/null || true

echo >> "security-scan-results/custom-patterns-$TIMESTAMP.txt"
echo "=== Tokens ===" >> "security-scan-results/custom-patterns-$TIMESTAMP.txt"

# Search for token patterns
grep -r -i --exclude-dir=.git --exclude-dir=node_modules --exclude="*.json" --exclude="security-scan.sh" \
    -E "(bearer|token|jwt|oauth)" . >> "security-scan-results/custom-patterns-$TIMESTAMP.txt" 2>/dev/null || true

echo -e "${GREEN}✅ Custom pattern search completed${NC}"
echo

# 4. FILE PERMISSION CHECK
echo -e "${YELLOW}🔍 Checking file permissions...${NC}"
echo "Looking for files with overly permissive permissions..."

find . -type f \( -perm -002 -o -perm -020 \) -not -path "./.git/*" > "security-scan-results/permissions-$TIMESTAMP.txt" 2>/dev/null || true

PERM_COUNT=$(wc -l < "security-scan-results/permissions-$TIMESTAMP.txt" 2>/dev/null || echo "0")
if [ "$PERM_COUNT" -gt 0 ]; then
    echo -e "${RED}⚠️  Found $PERM_COUNT files with overly permissive permissions${NC}"
else
    echo -e "${GREEN}✅ No permission issues found${NC}"
fi
echo

# 5. SUMMARY REPORT
echo -e "${YELLOW}📊 Generating summary report...${NC}"

cat > "security-scan-results/summary-$TIMESTAMP.txt" << EOF
Security Scan Summary Report
============================
Timestamp: $TIMESTAMP
Repository: $(pwd)

Scan Results:
- Gitleaks findings: ${GITLEAKS_COUNT:-"N/A"}
- TruffleHog findings: ${TRUFFLEHOG_COUNT:-"N/A"}
- Permission issues: ${PERM_COUNT:-"0"}

Files Generated:
- gitleaks-$TIMESTAMP.json
- trufflehog-$TIMESTAMP.json
- custom-patterns-$TIMESTAMP.txt
- permissions-$TIMESTAMP.txt
- summary-$TIMESTAMP.txt

Recommendations:
1. Review all findings in the JSON files
2. Rotate any exposed credentials immediately
3. Add sensitive patterns to .gitignore
4. Consider using git-secrets or pre-commit hooks
5. Set up regular automated scans

Next Steps:
1. Check AWS Console for any unauthorized access
2. Rotate AWS keys and tokens found in the scan
3. Update .gitignore to prevent future leaks
4. Consider using AWS Secrets Manager for credentials
EOF

echo -e "${GREEN}✅ Summary report generated${NC}"
echo

# 6. DISPLAY CRITICAL FINDINGS
echo -e "${RED}🚨 CRITICAL SECURITY FINDINGS:${NC}"
echo "================================"

if [ -f "security-scan-results/gitleaks-$TIMESTAMP.json" ] && [ "$GITLEAKS_COUNT" -gt 0 ]; then
    echo -e "${RED}⚠️  GITLEAKS FOUND SECRETS:${NC}"
    jq -r '.[] | "- Rule: \(.RuleID) | File: \(.File) | Secret: \(.Secret[0:20])..."' "security-scan-results/gitleaks-$TIMESTAMP.json" 2>/dev/null || echo "Error parsing Gitleaks results"
    echo
fi

echo -e "${YELLOW}📁 All results saved to: security-scan-results/${NC}"
echo -e "${YELLOW}🔍 Review the detailed JSON files for complete findings${NC}"
echo

echo "================================================"
echo -e "${GREEN}🔍 Security scan completed!${NC}"
echo
echo -e "${YELLOW}⚠️  IMPORTANT: If any real secrets were found, rotate them immediately!${NC}"
echo -e "${YELLOW}📖 Check the summary report: security-scan-results/summary-$TIMESTAMP.txt${NC}"
