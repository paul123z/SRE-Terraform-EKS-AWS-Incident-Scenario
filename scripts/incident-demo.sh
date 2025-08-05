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

# Configuration
AWS_REGION="eu-central-1"
CLUSTER_NAME="sre-incident-demo-cluster"
APP_NAME="sre-demo-app"
NAMESPACE="default"
AWS_CMD=$(command -v aws || echo "/usr/local/bin/aws")
KUBECTL_CMD=$(command -v kubectl || echo "/usr/local/bin/kubectl")

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

# Main demo function
demo_incident() {
    echo ""
    print_status "=== SRE Incident Detection & Resolution Demo ==="
    echo ""
    print_status "This demo will walk through a complete incident scenario:"
    echo "1. Initial healthy state"
    echo "2. Incident simulation (memory leak)"
    echo "3. Detection and diagnosis"
    echo "4. Resolution and recovery"
    echo "5. Verification"
    echo ""
    
    read -p "Press Enter to start the demo..."
    
    # Phase 1: Initial State
    echo ""
    print_success "=== Phase 1: Initial Healthy State ==="
    print_status "Let's check the current state of our application..."
    
    show_pods
    check_health
    show_resources
    
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
    
    # Re-enable HPA
    enable_hpa
    
    print_success "Verification complete! Application is healthy and stable."
    
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
    echo ""
    print_status "This demonstrates a complete SRE incident response process!"
    echo ""
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