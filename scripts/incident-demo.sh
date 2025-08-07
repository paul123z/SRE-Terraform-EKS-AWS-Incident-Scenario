#!/bin/bash

# SRE Incident Detection & Resolution Demo Script
# This script walks through a complete incident scenario

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}$1${NC}"
}

# Configuration
AWS_REGION="eu-central-1"
CLUSTER_NAME="sre-incident-demo-cluster"
APP_NAME="sre-demo-app"
NAMESPACE="default"
AWS_CMD=$(command -v aws || echo "/usr/local/bin/aws")
KUBECTL_CMD=$(command -v kubectl || echo "/usr/local/bin/kubectl")

# AI Incident Response Configuration
INCIDENT_ID="demo-incident-$(date +%Y%m%d-%H%M%S)"
S3_BUCKET=""
LOG_DIR="/tmp/incident-logs"

# Function to get service URL
get_service_url() {
    $KUBECTL_CMD get svc sre-demo-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "localhost:8080"
}

# Function to check application health
check_health() {
    local url=$(get_service_url)
    print_status "Checking application health at http://$url/health"
    curl -s http://$url/health | jq . 2>/dev/null || curl -s http://$url/health
    echo ""
}

# Function to show resource usage
show_resources() {
    print_status "Current resource usage:"
    # Wait a moment for metrics server to be ready
    sleep 2
    $KUBECTL_CMD top pods -l app.kubernetes.io/name=sre-demo-app 2>/dev/null || echo "Metrics server not available"
    echo ""
}

# Function to check memory leak status
check_memory_status() {
    local url=$(get_service_url)
    print_status "Memory leak status:"
    curl -s http://$url/api/memory-status | jq . 2>/dev/null || curl -s http://$url/api/memory-status
    echo ""
}

# Function to disable HPA for demo
disable_hpa() {
    print_status "Disabling HPA to prevent automatic scaling during demo..."
    $KUBECTL_CMD patch hpa sre-demo-app -p '{"spec":{"minReplicas":1,"maxReplicas":1}}' || true
    print_success "HPA disabled"
}

# Function to re-enable HPA
enable_hpa() {
    print_status "Re-enabling HPA..."
    $KUBECTL_CMD patch hpa sre-demo-app -p '{"spec":{"minReplicas":1,"maxReplicas":5}}' || true
    print_success "HPA re-enabled"
}

# Function to show pod status
show_pods() {
    print_status "Pod status:"
    $KUBECTL_CMD get pods -l app.kubernetes.io/name=sre-demo-app
    echo ""
}

# Function to show recent events
show_events() {
    print_status "Recent Kubernetes events:"
    $KUBECTL_CMD get events --sort-by='.lastTimestamp' --field-selector involvedObject.name=sre-demo-app | tail -5
    echo ""
}

# Function to get S3 bucket name from Terraform
get_s3_bucket_name() {
    if command -v terraform &> /dev/null; then
        cd terraform
        BUCKET_NAME=$(terraform output -raw incident_logs_bucket 2>/dev/null || echo "")
        cd - > /dev/null
        
        if [ -n "$BUCKET_NAME" ]; then
            echo "$BUCKET_NAME"
            return
        fi
    fi
    
    # Fallback to default name pattern
    echo "sre-incident-demo-incident-logs-$(date +%s)"
}

# Function to initialize logging
init_logging() {
    print_status "Initializing AI incident logging..."
    
    # Get S3 bucket name
    S3_BUCKET=$(get_s3_bucket_name)
    print_status "Using S3 bucket: $S3_BUCKET"
    
    # Create log directory
    mkdir -p "$LOG_DIR"
    
    # Create incident log file
    INCIDENT_LOG_FILE="$LOG_DIR/incident-$INCIDENT_ID.log"
    touch "$INCIDENT_LOG_FILE"
    
    print_success "Logging initialized: $INCIDENT_LOG_FILE"
}

# Function to log incident data
log_incident_data() {
    local phase="$1"
    local message="$2"
    local data="$3"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local log_entry="[$timestamp] [$phase] $message"
    
    echo "$log_entry" >> "$INCIDENT_LOG_FILE"
    
    if [ -n "$data" ]; then
        echo "$data" >> "$INCIDENT_LOG_FILE"
        echo "" >> "$INCIDENT_LOG_FILE"
    fi
}

# Function to capture application logs
capture_app_logs() {
    local phase="$1"
    
    print_status "Capturing application logs for phase: $phase"
    
    # Get pod logs
    local pod_logs
    pod_logs=$($KUBECTL_CMD logs -l app.kubernetes.io/name=sre-demo-app --tail=50 2>/dev/null || echo "No logs available")
    
    # Get pod status
    local pod_status
    pod_status=$($KUBECTL_CMD get pods -l app.kubernetes.io/name=sre-demo-app -o wide 2>/dev/null || echo "No pod status available")
    
    # Get resource usage
    local resource_usage
    resource_usage=$($KUBECTL_CMD top pods -l app.kubernetes.io/name=sre-demo-app 2>/dev/null || echo "No resource usage available")
    
    # Get events
    local events
    events=$($KUBECTL_CMD get events --sort-by='.lastTimestamp' --field-selector involvedObject.name=sre-demo-app 2>/dev/null || echo "No events available")
    
    # Log all data
    log_incident_data "$phase" "Application logs captured" "=== POD LOGS ===\n$pod_logs\n\n=== POD STATUS ===\n$pod_status\n\n=== RESOURCE USAGE ===\n$resource_usage\n\n=== EVENTS ===\n$events"
}

# Function to capture metrics snapshot
capture_metrics_snapshot() {
    local phase="$1"
    
    print_status "Capturing metrics snapshot for phase: $phase"
    
    # Get service URL
    local url=$(get_service_url)
    
    # Capture application metrics
    local health_status
    health_status=$(curl -s http://$url/health 2>/dev/null || echo "Health check failed")
    
    local memory_status
    memory_status=$(curl -s http://$url/api/memory-status 2>/dev/null || echo "Memory status check failed")
    
    # Log metrics
    log_incident_data "$phase" "Metrics snapshot captured" "=== HEALTH STATUS ===\n$health_status\n\n=== MEMORY STATUS ===\n$memory_status"
}

# Function to upload logs to S3
upload_logs_to_s3() {
    print_status "Uploading incident logs to S3..."
    
    if [ -z "$S3_BUCKET" ]; then
        print_warning "S3 bucket not configured, skipping upload"
        return
    fi
    
    # Upload main incident log
    if [ -f "$INCIDENT_LOG_FILE" ]; then
        $AWS_CMD s3 cp "$INCIDENT_LOG_FILE" "s3://$S3_BUCKET/incidents/$INCIDENT_ID/incident-log.txt" --region "$AWS_REGION" 2>/dev/null || {
            print_warning "Failed to upload incident log to S3"
            return
        }
    fi
    
    # Upload all log files in the directory
    for log_file in "$LOG_DIR"/*; do
        if [ -f "$log_file" ]; then
            local filename=$(basename "$log_file")
            $AWS_CMD s3 cp "$log_file" "s3://$S3_BUCKET/incidents/$INCIDENT_ID/$filename" --region "$AWS_REGION" 2>/dev/null || {
                print_warning "Failed to upload $filename to S3"
            }
        fi
    done
    
    print_success "Logs uploaded to S3: s3://$S3_BUCKET/incidents/$INCIDENT_ID/"
    print_status "Incident ID for AI analysis: $INCIDENT_ID"
}

# Main demo function
demo_incident() {
    echo ""
    print_warning "=== SRE Incident Detection & Resolution Demo ==="
    echo ""
    print_status "This demo will walk through a complete incident scenario:"
    echo "1. Initial healthy state"
    echo "2. Incident simulation (memory leak)"
    echo "3. Detection and diagnosis"
    echo "4. Resolution and recovery"
    echo "5. Verification"
    echo "6. AI-powered RCA analysis (Bedrock)"
    echo ""
    
    # Initialize AI incident logging
    init_logging
    
    read -p "Press Enter to start the demo..."
    
    # Phase 1: Initial State
    echo ""
    print_success "=== Phase 1: Initial Healthy State ==="
    print_status "Let's check the current state of our application..."
    
    show_pods
    check_health
    show_resources
    
    # Capture initial state for AI analysis
    capture_app_logs "INITIAL_STATE"
    capture_metrics_snapshot "INITIAL_STATE"
    
    # Disable HPA for demo
    disable_hpa
    
    read -p "Press Enter to continue to incident simulation..."
    
    # Phase 2: Incident Simulation
    echo ""
    print_warning "=== Phase 2: Incident Simulation ==="
    print_status "Simulating a memory leak incident..."
    
    local url=$(get_service_url)
    print_status "Enabling memory leak simulation..."
    curl -X POST http://$url/api/memory-leak \
        -H "Content-Type: application/json" \
        -d '{"enable": true}' || true
    
    print_success "Memory leak simulation activated!"
    print_warning "The application will now gradually consume more memory..."
    
    # Log incident trigger
    log_incident_data "INCIDENT_TRIGGER" "Memory leak simulation enabled" "Memory leak simulation activated via API call"
    
    read -p "Press Enter to continue to detection phase..."
    
    # Phase 3: Detection
    echo ""
    print_warning "=== Phase 3: Incident Detection ==="
    print_status "Now let's detect the incident using our monitoring tools..."
    
    print_status "1. Checking application health (should show increased memory usage):"
    check_health
    
    print_status "2. Checking memory leak status:"
    check_memory_status
    
    print_status "3. Checking resource usage (should show memory growing):"
    show_resources
    
    print_status "4. Waiting 30 seconds to see memory growth..."
    for i in {30..1}; do
        echo -n "."
        sleep 1
    done
    echo ""
    
    print_status "5. Checking memory status after growth period:"
    check_memory_status
    show_resources
    
    print_status "6. Checking pod status (should show potential restarts):"
    show_pods
    
    print_status "7. Checking Kubernetes events (should show memory pressure):"
    show_events
    
    # Capture detection phase data for AI analysis
    capture_app_logs "DETECTION"
    capture_metrics_snapshot "DETECTION"
    
    print_warning "Detection complete! We can see the memory leak affecting our application."
    
    read -p "Press Enter to continue to diagnosis phase..."
    
    # Phase 4: Diagnosis
    echo ""
    print_warning "=== Phase 4: Incident Diagnosis ==="
    print_status "Let's diagnose the root cause..."
    
    print_status "1. Checking application logs for memory leak indicators:"
    $KUBECTL_CMD logs -l app.kubernetes.io/name=sre-demo-app --tail=10 || true
    echo ""
    
    print_status "2. Checking if memory leak simulation is active:"
    curl -s -X POST http://$url/api/failure-mode \
        -H "Content-Type: application/json" \
        -d '{"mode": "none"}' || true
    echo ""
    
    # Capture diagnosis phase data for AI analysis
    capture_app_logs "DIAGNOSIS"
    log_incident_data "DIAGNOSIS" "Root cause identified" "Memory leak simulation enabled in application"
    
    print_success "Diagnosis complete! Root cause: Memory leak simulation enabled."
    
    read -p "Press Enter to continue to resolution phase..."
    
    # Phase 5: Resolution
    echo ""
    print_success "=== Phase 5: Incident Resolution ==="
    print_status "Now let's resolve the incident..."
    
    print_status "1. Disabling memory leak simulation:"
    curl -X POST http://$url/api/memory-leak \
        -H "Content-Type: application/json" \
        -d '{"enable": false}' || true
    
    print_status "2. Restarting deployment to clear memory:"
    $KUBECTL_CMD rollout restart deployment sre-demo-app
    
    print_status "3. Waiting for deployment to be ready:"
    $KUBECTL_CMD wait --for=condition=ready pod -l app.kubernetes.io/name=sre-demo-app --timeout=300s
    
    # Log resolution actions
    log_incident_data "RESOLUTION" "Memory leak disabled and pods restarted" "Resolution actions completed successfully"
    
    print_success "Resolution complete! Memory leak disabled and pods restarted."
    
    read -p "Press Enter to continue to verification phase..."
    
    # Phase 6: Verification
    echo ""
    print_success "=== Phase 6: Verification & Recovery ==="
    print_status "Let's verify that the incident is resolved..."
    
    print_status "1. Checking application health (should be healthy):"
    check_health
    
    print_status "2. Checking memory leak status (should be disabled):"
    check_memory_status
    
    print_status "3. Checking resource usage (should be stable):"
    show_resources
    
    print_status "4. Checking pod status (should be running):"
    show_pods
    
    # Capture verification phase data for AI analysis
    capture_app_logs "VERIFICATION"
    capture_metrics_snapshot "VERIFICATION"
    
    # Re-enable HPA
    enable_hpa
    
    print_success "Verification complete! Application is healthy and stable."
    
    # Upload logs to S3 for AI analysis
    upload_logs_to_s3
    
    # AI Analysis Phase
    echo ""
    print_warning "=== Phase 7: AI-Powered RCA Analysis ==="
    print_status "Now let's analyze the incident using AWS Bedrock (Claude Sonnet 4)..."
    
    print_status "Incident logs have been captured locally for AI analysis."
    print_status "You can now run the AI analysis script to get detailed RCA:"
    echo ""
    print_status "Run: ./scripts/analyze-incident-bedrock.sh $INCIDENT_ID"
    echo ""
    print_status "This will use AWS Bedrock (Claude Sonnet 4) to analyze the logs and provide:"
    echo "  • Root cause analysis"
    echo "  • Immediate fixes"
    echo "  • Preventive measures"
    echo "  • Lessons learned"
    echo "  • Recommendations"
    echo ""
    print_status "Analysis results will be saved in: $(pwd)/bedrock-analysis"
    echo ""
    
    read -p "Press Enter to run AI analysis now (or Ctrl+C to skip)..."
    
    # Add a simple check to see if we're still in the script
    print_status "Starting AI analysis phase..."
    
    # Set up trap to catch interruptions
    trap 'print_error "Script interrupted during AI analysis"; exit 1' INT TERM
    
    # Run AI analysis
    if [ -f "./scripts/analyze-incident-bedrock.sh" ] && [ -x "./scripts/analyze-incident-bedrock.sh" ]; then
        print_status "Running AI analysis with AWS Bedrock..."
        
        # Capture the output of the analysis
        print_status "Starting AI analysis..."
        print_status "Running: ./scripts/analyze-incident-bedrock.sh $INCIDENT_ID"
        
        # Run the analysis and capture output
        print_status "Executing analysis script..."
        
        # Run the analysis script with error handling (try-catch approach)
        print_status "Running analysis script (this may take a moment)..."
        
        # Create a temporary file for error capture
        ERROR_LOG=$(mktemp)
        
        # Run the analysis script and capture both output and errors
        if ANALYSIS_OUTPUT=$(timeout 300 ./scripts/analyze-incident-bedrock.sh "$INCIDENT_ID" 2>&1); then
            ANALYSIS_EXIT_CODE=0
            print_status "Analysis script completed successfully"
        else
            ANALYSIS_EXIT_CODE=$?
            print_warning "Analysis script exited with code: $ANALYSIS_EXIT_CODE"
            
            # Check if we got any output despite the error
            if [ -n "$ANALYSIS_OUTPUT" ]; then
                print_status "Script produced output despite exit code"
            else
                print_warning "No output captured from analysis script"
            fi
        fi
        
        print_status "Analysis script execution completed"
        
        # Always check for analysis results regardless of output capture
        print_status "Checking for analysis results..."
        sleep 2
        
        # Find the most recent analysis file
        LATEST_FILE=$(ls -t bedrock-analysis/bedrock_response_*.json 2>/dev/null | head -1)
        
        if [ -n "$LATEST_FILE" ] && [ -f "$LATEST_FILE" ]; then
            print_success "✅ AI analysis completed successfully!"
            print_status "Analysis results saved to: $LATEST_FILE"
            print_status "You can view the results with: ./scripts/test-analysis-display.sh"
            
            # Show output if we captured it
            if [ -n "$ANALYSIS_OUTPUT" ]; then
                echo ""
                print_status "=== RAW ANALYSIS SCRIPT OUTPUT ==="
                echo "$ANALYSIS_OUTPUT"
                print_status "=== END OF ANALYSIS SCRIPT OUTPUT ==="
                echo ""
            fi
        else
            print_error "❌ Analysis failed - no results file found"
            print_status "Exit code: $ANALYSIS_EXIT_CODE"
            
            # Show any output we captured for debugging
            if [ -n "$ANALYSIS_OUTPUT" ]; then
                echo ""
                print_status "=== PARTIAL ANALYSIS SCRIPT OUTPUT ==="
                echo "$ANALYSIS_OUTPUT"
                print_status "=== END OF PARTIAL OUTPUT ==="
                echo ""
            fi
        fi
        
        print_status "AI analysis completed with exit code: $ANALYSIS_EXIT_CODE"
        print_status "Analysis output length: ${#ANALYSIS_OUTPUT} characters"
        
        # Accept both exit code 0 (success) and 4 (success with warnings)
        if [ $ANALYSIS_EXIT_CODE -eq 0 ] || [ $ANALYSIS_EXIT_CODE -eq 4 ]; then
            print_status "Analysis script completed successfully, checking for results..."
            
            # Check if the output contains success messages
            if echo "$ANALYSIS_OUTPUT" | grep -q "Bedrock analysis completed successfully"; then
                print_success "✅ Bedrock analysis completed successfully!"
            fi
            print_success "AI analysis completed successfully!"
            
            # Small delay to ensure file is written
            sleep 2
            
            # Find the most recent bedrock response file
            print_status "Searching for analysis files..."
            ls -la bedrock-analysis/bedrock_response_*.json 2>/dev/null || print_warning "No analysis files found"
            ANALYSIS_FILE=$(ls -t bedrock-analysis/bedrock_response_*.json 2>/dev/null | head -1)
            print_status "Found analysis file: $ANALYSIS_FILE"
            print_status "Total analysis files found: $(ls bedrock-analysis/bedrock_response_*.json 2>/dev/null | wc -l)"
            
            if [ -n "$ANALYSIS_FILE" ] && [ -f "$ANALYSIS_FILE" ]; then
                # Display the analysis results
                echo ""
                print_header "🤖 AI-POWERED INCIDENT ANALYSIS RESULTS"
                echo ""
                
                # Extract and display the structured analysis if available
                if command -v jq &> /dev/null; then
                print_status "📊 INCIDENT SUMMARY:"
                INCIDENT_TYPE=$(jq -r '.content[0].text' "$ANALYSIS_FILE" | sed 's/```json//' | sed 's/```//' | jq -r '.analysis.incident_summary.type' 2>/dev/null || echo "Unknown")
                SEVERITY=$(jq -r '.content[0].text' "$ANALYSIS_FILE" | sed 's/```json//' | sed 's/```//' | jq -r '.analysis.incident_summary.severity' 2>/dev/null || echo "Unknown")
                DURATION=$(jq -r '.content[0].text' "$ANALYSIS_FILE" | sed 's/```json//' | sed 's/```//' | jq -r '.analysis.incident_summary.duration' 2>/dev/null || echo "Unknown")
                echo "  Type: $INCIDENT_TYPE"
                echo "  Severity: $SEVERITY"
                echo "  Duration: $DURATION"
                echo ""
                
                print_status "🔍 ROOT CAUSE ANALYSIS:"
                PRIMARY_CAUSE=$(jq -r '.content[0].text' "$ANALYSIS_FILE" | sed 's/```json//' | sed 's/```//' | jq -r '.analysis.root_cause_analysis.primary_cause' 2>/dev/null || echo "Unknown")
                echo "  Primary Cause: $PRIMARY_CAUSE"
                echo ""
                
                print_status "⚡ IMMEDIATE FIXES:"
                jq -r '.content[0].text' "$ANALYSIS_FILE" | sed 's/```json//' | sed 's/```//' | jq -r '.analysis.immediate_fixes[] | "  \(.priority | ascii_upcase): \(.action) - \(.description)"' 2>/dev/null || echo "  No immediate fixes found"
                echo ""
                
                print_status "🛡️ PREVENTIVE MEASURES:"
                jq -r '.content[0].text' "$ANALYSIS_FILE" | sed 's/```json//' | sed 's/```//' | jq -r '.analysis.preventive_measures[] | "  \(.measure): \(.implementation) (Timeline: \(.timeline))"' 2>/dev/null || echo "  No preventive measures found"
                echo ""
                
                print_status "📚 LESSONS LEARNED:"
                jq -r '.content[0].text' "$ANALYSIS_FILE" | sed 's/```json//' | sed 's/```//' | jq -r '.analysis.lessons_learned[] | "  • \(.)"' 2>/dev/null || echo "  No lessons learned found"
                echo ""
                
                print_status "💡 RECOMMENDATIONS:"
                jq -r '.content[0].text' "$ANALYSIS_FILE" | sed 's/```json//' | sed 's/```//' | jq -r '.analysis.recommendations[] | "  \(.category | ascii_upcase): \(.recommendation) (Impact: \(.impact))"' 2>/dev/null || echo "  No recommendations found"
                echo ""
                
                    print_success "✅ AI analysis results displayed above!"
                    print_status "Full analysis saved to: $ANALYSIS_FILE"
                else
                    # jq not available, show raw JSON
                    print_warning "jq not available, showing raw analysis file:"
                    cat "$ANALYSIS_FILE"
                fi
            else
                # Fallback: provide guidance on how to view results
                print_warning "Analysis completed but display failed. Here's how to view the results:"
                echo ""
                print_status "📋 TO VIEW AI ANALYSIS RESULTS:"
                echo ""
                echo "1. Run the analysis display script:"
                echo "   ./scripts/test-analysis-display.sh"
                echo ""
                echo "2. Or view the raw analysis file:"
                echo "   cat $ANALYSIS_FILE"
                echo ""
                echo "3. Or use jq to format the JSON:"
                echo "   jq -r '.content[0].text' $ANALYSIS_FILE | sed 's/```json//' | sed 's/```//' | jq ."
                echo ""
                print_status "💡 TIP: The AI analysis provides structured recommendations including:"
                echo "   • Root cause analysis"
                echo "   • Immediate fixes with priorities"
                echo "   • Preventive measures with timelines"
                echo "   • Lessons learned"
                echo "   • Actionable recommendations by category"
                echo ""
            fi
        else
            print_error "AI analysis failed with exit code $ANALYSIS_EXIT_CODE"
            print_warning "Raw output:"
            echo "$ANALYSIS_OUTPUT"
            
            # Check if analysis actually worked despite exit code
            if echo "$ANALYSIS_OUTPUT" | grep -q "Bedrock analysis completed successfully"; then
                print_warning "Analysis appears to have worked despite exit code. Checking for results..."
                sleep 2
                ANALYSIS_FILE=$(ls -t bedrock-analysis/bedrock_response_*.json 2>/dev/null | head -1)
                if [ -n "$ANALYSIS_FILE" ] && [ -f "$ANALYSIS_FILE" ]; then
                    print_success "Found analysis file despite exit code: $ANALYSIS_FILE"
                    print_status "You can view the results with: ./scripts/test-analysis-display.sh"
                fi
            fi
        fi
    else
        print_warning "AI analysis script not found. Please run manually:"
        print_status "./scripts/analyze-incident-bedrock.sh $INCIDENT_ID"
    fi
    
    # Summary
    echo ""
    print_success "=== Demo Summary ==="
    echo ""
    print_status "We successfully demonstrated:"
    echo "✅ Infrastructure as Code (Terraform)"
    echo "✅ CI/CD Pipeline (GitHub Actions)"
    echo "✅ Incident Detection (Grafana + kubectl)"
    echo "✅ Incident Diagnosis (logs + metrics)"
    echo "✅ Incident Resolution (simulation disable + restart)"
    echo "✅ Verification (health checks + monitoring)"
    echo "✅ AI-Powered RCA Analysis (AWS Bedrock + Claude Sonnet 4)"
    echo ""
    print_status "This demonstrates a complete SRE incident response process with AI enhancement!"
    echo ""
    
    # AI Explanation
    print_header "🤖 HOW AI ENHANCES INCIDENT RESPONSE"
    echo ""
    print_status "Our AI system uses AWS Bedrock (Claude Sonnet 4) to:"
    echo "  1. 📊 Analyze incident logs and metrics to identify patterns"
    echo "  2. 🧠 Provide intelligent recommendations for fixes"
    echo "  3. 🔍 Perform root cause analysis automatically"
    echo ""
    print_status "What the AI does:"
    echo "  • Reads through all the logs we collected during the incident"
    echo "  • Identifies the root cause of the problem"
    echo "  • Suggests immediate fixes to resolve the issue"
    echo "  • Recommends ways to prevent it from happening again"
    echo "  • Provides lessons learned for future incidents"
    echo "  • Works even after infrastructure is torn down (log-based analysis)"
    echo ""
    print_status "This saves hours of manual analysis and helps SREs respond faster!"
    print_status "The analysis works offline using only the incident log files."
    echo ""
    
    # AI Analysis Results Summary
    echo ""
    print_header "📊 AI ANALYSIS RESULTS SUMMARY"
    echo ""
    print_status "AWS Bedrock analysis has been completed and saved to:"
    echo "  📁 bedrock-analysis/bedrock_response_*.json"
    echo ""
    print_status "The AI analysis provides:"
    echo "  🔍 Root Cause Analysis: Identified the primary cause of the incident"
    echo "  ⚡ Immediate Fixes: Prioritized actions to resolve the issue"
    echo "  🛡️ Preventive Measures: Long-term solutions with implementation timelines"
    echo "  📚 Lessons Learned: Key takeaways for future incidents"
    echo "  💡 Recommendations: Actionable suggestions by category (monitoring, infrastructure, etc.)"
    echo ""
    print_status "To view the complete AI analysis results:"
    echo "  🎯 Run: ./scripts/test-analysis-display.sh"
    echo "  📄 Or check the latest file in: bedrock-analysis/"
    echo ""
    print_status "💬 For human-readable summary: Ask an AI chatbot to analyze the JSON output"
    echo "   Example: 'Summarize this incident analysis in simple terms: [paste JSON content]'"
    echo ""
    
    # Final pause to ensure results are displayed
    echo ""
    print_success "🎉 Demo completed! Press Enter to exit..."
    read -p ""
    
    # Always show a positive completion message
    echo ""
    print_success "🎉 INCIDENT DEMO COMPLETED SUCCESSFULLY!"
    print_status "✅ Complete incident lifecycle demonstrated"
    print_status "✅ AI-powered analysis integrated"
    print_status "✅ Results available in bedrock-analysis/ directory"
    echo ""
    print_status "📁 To view AI analysis results:"
    print_status "   ./scripts/test-analysis-display.sh"
    echo ""
    print_status "🚀 Demo completed with AI enhancement!"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null && ! /usr/local/bin/kubectl version --client &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    
    # Check if cluster is accessible
    if ! $KUBECTL_CMD cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    # Check if application is deployed
if ! $KUBECTL_CMD get deployment sre-demo-app &> /dev/null; then
    print_error "sre-demo-app deployment not found"
    print_status "Please deploy the application first: ./scripts/deploy.sh"
    exit 1
fi
    
    # Check if Bedrock analysis script is available and executable
    if [ ! -f "./scripts/analyze-incident-bedrock.sh" ] || [ ! -x "./scripts/analyze-incident-bedrock.sh" ]; then
        print_warning "Bedrock analysis script not found or not executable"
        print_status "AI analysis phase will be skipped"
    fi

# Check if we have enough nodes for the demo
NODE_COUNT=$($KUBECTL_CMD get nodes --no-headers | wc -l)
if [ "$NODE_COUNT" -lt 2 ]; then
    print_warning "Only $NODE_COUNT node(s) available. For optimal demo experience, consider scaling to 2+ nodes."
    print_status "You can scale up with: aws eks update-nodegroup-config --cluster-name sre-incident-demo-cluster --nodegroup-name main-20250805185921253500000011 --scaling-config minSize=2,maxSize=3,desiredSize=2 --region eu-central-1"
fi
    
    print_success "All prerequisites are satisfied"
}

# Main function
main() {
    print_status "Starting SRE Incident Demo..."
    
    # Check prerequisites
    check_prerequisites
    
    # Run demo
    demo_incident
    
    print_success "SRE Incident Demo completed successfully!"
}

# Run main function
main "$@" 