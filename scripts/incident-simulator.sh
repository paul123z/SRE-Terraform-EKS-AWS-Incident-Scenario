#!/bin/bash

# SRE Incident Simulator Script
# This script simulates various failure scenarios for demonstration purposes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="sre-demo-app"
NAMESPACE="default"
SERVICE_URL=""
AWS_CMD=$(command -v aws || echo "/usr/local/bin/aws")
KUBECTL_CMD=$(command -v kubectl || echo "/usr/local/bin/kubectl")

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

# Function to get service URL
get_service_url() {
    print_status "Getting service URL..."
    SERVICE_URL=$($KUBECTL_CMD get svc $APP_NAME -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    if [ -z "$SERVICE_URL" ]; then
        SERVICE_URL=$($KUBECTL_CMD get svc $APP_NAME -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    fi
    print_success "Service URL: http://$SERVICE_URL"
}

# Function to check application health
check_health() {
    print_status "Checking application health..."
    if curl -f http://$SERVICE_URL/health > /dev/null 2>&1; then
        print_success "Application is healthy"
        return 0
    else
        print_error "Application is unhealthy"
        return 1
    fi
}

# Function to simulate health check failure
simulate_health_failure() {
    print_status "Simulating health check failure..."
    curl -X POST http://$SERVICE_URL/api/failure-mode \
        -H "Content-Type: application/json" \
        -d '{"mode": "health_failure"}'
    print_warning "Health check failure mode activated"
    sleep 5
    check_health
}

# Function to simulate slow response
simulate_slow_response() {
    print_status "Simulating slow response..."
    curl -X POST http://$SERVICE_URL/api/failure-mode \
        -H "Content-Type: application/json" \
        -d '{"mode": "slow_response"}'
    print_warning "Slow response mode activated"
    sleep 5
    check_health
}

# Function to simulate memory leak
simulate_memory_leak() {
    print_status "Simulating memory leak..."
    curl -X POST http://$SERVICE_URL/api/memory-leak \
        -H "Content-Type: application/json" \
        -d '{"enable": true}'
    print_warning "Memory leak simulation activated"
}

# Function to simulate CPU stress
simulate_cpu_stress() {
    print_status "Simulating CPU stress..."
    curl -X POST http://$SERVICE_URL/api/cpu-stress \
        -H "Content-Type: application/json" \
        -d '{"enable": true}'
    print_warning "CPU stress simulation activated"
}

# Function to reset all simulations
reset_simulations() {
    print_status "Resetting all simulations..."
    curl -X POST http://$SERVICE_URL/api/failure-mode \
        -H "Content-Type: application/json" \
        -d '{"mode": "none"}'
    curl -X POST http://$SERVICE_URL/api/memory-leak \
        -H "Content-Type: application/json" \
        -d '{"enable": false}'
    curl -X POST http://$SERVICE_URL/api/cpu-stress \
        -H "Content-Type: application/json" \
        -d '{"enable": false}'
    print_success "All simulations reset"
}

# Function to show pod status
show_pod_status() {
    print_status "Current pod status:"
    $KUBECTL_CMD get pods -l app.kubernetes.io/name=$APP_NAME -n $NAMESPACE
    echo ""
    print_status "Pod logs:"
    $KUBECTL_CMD logs -l app.kubernetes.io/name=$APP_NAME -n $NAMESPACE --tail=10
}

# Function to show metrics
show_metrics() {
    print_status "Current resource usage:"
    $KUBECTL_CMD top pods -l app.kubernetes.io/name=$APP_NAME -n $NAMESPACE
}

# Function to show HPA status
show_hpa_status() {
    print_status "HPA status:"
    $KUBECTL_CMD get hpa -n $NAMESPACE
}

# Function to show service status
show_service_status() {
    print_status "Service status:"
    $KUBECTL_CMD get svc $APP_NAME -n $NAMESPACE
}

# Function to scale application
scale_app() {
    local replicas=$1
    print_status "Scaling application to $replicas replicas..."
    $KUBECTL_CMD scale deployment $APP_NAME -n $NAMESPACE --replicas=$replicas
    print_success "Scaled to $replicas replicas"
}

# Function to restart application
restart_app() {
    print_status "Restarting application..."
    $KUBECTL_CMD rollout restart deployment $APP_NAME -n $NAMESPACE
    print_success "Application restart initiated"
}

# Function to show incident timeline
show_incident_timeline() {
    echo ""
    print_status "=== INCIDENT TIMELINE ==="
    echo "1. Application deployed and running normally"
    echo "2. Incident simulation triggered"
    echo "3. Monitoring detects issues"
    echo "4. Investigation begins"
    echo "5. Root cause identified"
    echo "6. Resolution applied"
    echo "7. Verification of fix"
    echo "8. Post-incident review"
    echo ""
}

# Main menu
show_menu() {
    echo ""
    echo "=== SRE Incident Simulator ==="
    echo "1. Check application health"
    echo "2. Simulate health check failure"
    echo "3. Simulate slow response"
    echo "4. Simulate memory leak"
    echo "5. Simulate CPU stress"
    echo "6. Reset all simulations"
    echo "7. Show pod status"
    echo "8. Show metrics"
    echo "9. Show HPA status"
    echo "10. Show service status"
    echo "11. Scale application"
    echo "12. Restart application"
    echo "13. Show incident timeline"
    echo "14. Exit"
    echo ""
}

# Main function
main() {
    print_status "Starting SRE Incident Simulator..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null && ! /usr/local/bin/kubectl version --client &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check if application is deployed
    if ! $KUBECTL_CMD get deployment $APP_NAME -n $NAMESPACE &> /dev/null; then
        print_error "Application $APP_NAME not found in namespace $NAMESPACE"
        print_status "Please deploy the application first"
        exit 1
    fi
    
    # Get service URL
    get_service_url
    
    # Main loop
    while true; do
        show_menu
        read -p "Select an option (1-14): " choice
        
        case $choice in
            1)
                check_health
                ;;
            2)
                simulate_health_failure
                ;;
            3)
                simulate_slow_response
                ;;
            4)
                simulate_memory_leak
                ;;
            5)
                simulate_cpu_stress
                ;;
            6)
                reset_simulations
                ;;
            7)
                show_pod_status
                ;;
            8)
                show_metrics
                ;;
            9)
                show_hpa_status
                ;;
            10)
                show_service_status
                ;;
            11)
                read -p "Enter number of replicas: " replicas
                scale_app $replicas
                ;;
            12)
                restart_app
                ;;
            13)
                show_incident_timeline
                ;;
            14)
                print_success "Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid option. Please try again."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run main function
main "$@" 