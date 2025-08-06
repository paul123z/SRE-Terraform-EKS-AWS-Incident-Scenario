#!/bin/bash

# Kubernetes Dashboard Access Script
# This script sets up and provides access to the Kubernetes Dashboard

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
NAMESPACE="kubernetes-dashboard"
DASHBOARD_URL="http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"

# Function to check if dashboard is installed
check_dashboard_installation() {
    print_status "Checking Kubernetes Dashboard installation..."
    
    if ! kubectl get namespace $NAMESPACE &> /dev/null; then
        print_error "Kubernetes Dashboard namespace not found."
        print_error "The dashboard should be installed during deployment. Please run ./scripts/deploy.sh first."
        exit 1
    fi
    
    if ! kubectl get pods -n $NAMESPACE -l k8s-app=kubernetes-dashboard &> /dev/null; then
        print_error "Kubernetes Dashboard pods not found."
        print_error "The dashboard should be installed during deployment. Please run ./scripts/deploy.sh first."
        exit 1
    fi
    
    print_success "Kubernetes Dashboard is installed"
}

# Function to install dashboard
install_dashboard() {
    print_status "Installing Kubernetes Dashboard..."
    
    # Install the dashboard
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
    
    # Create admin service account
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dashboard-admin
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dashboard-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: dashboard-admin
  namespace: kubernetes-dashboard
EOF
    
    # Wait for dashboard pods to be ready
    print_status "Waiting for Kubernetes Dashboard to be ready..."
    kubectl wait --for=condition=ready pod -l app=kubernetes-dashboard -n $NAMESPACE --timeout=120s
    
    print_success "Kubernetes Dashboard installed successfully"
}

# Function to check dashboard status
check_dashboard_status() {
    print_status "Checking dashboard status..."
    
    # Check if pods are running
    local pod_count=$(kubectl get pods -n $NAMESPACE -l k8s-app=kubernetes-dashboard --no-headers | grep -c "Running" || echo "0")
    
    if [ "$pod_count" -eq 0 ]; then
        print_error "Dashboard pods are not running"
        print_status "Checking pod status..."
        kubectl get pods -n $NAMESPACE -l k8s-app=kubernetes-dashboard
        return 1
    fi
    
    # Check if service has endpoints
    local endpoint_count=$(kubectl get endpoints kubernetes-dashboard -n $NAMESPACE -o jsonpath='{.subsets[0].addresses}' | jq length 2>/dev/null || echo "0")
    
    if [ "$endpoint_count" -eq 0 ]; then
        print_error "Dashboard service has no endpoints"
        return 1
    fi
    
    print_success "Dashboard is ready"
    return 0
}

# Function to generate access token
generate_token() {
    print_status "Generating access token..."
    
    # Check if service account exists
    if ! kubectl get serviceaccount dashboard-admin -n $NAMESPACE &> /dev/null; then
        print_error "Dashboard admin service account not found"
        print_status "Creating service account..."
        
        kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dashboard-admin
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dashboard-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: dashboard-admin
  namespace: kubernetes-dashboard
EOF
    fi
    
    # Generate token
    local token=$(kubectl create token dashboard-admin -n $NAMESPACE)
    
    if [ -z "$token" ]; then
        print_error "Failed to generate token"
        return 1
    fi
    
    print_success "Token generated successfully"
    echo ""
    print_status "📋 Copy this token and paste it in the Kubernetes Dashboard:"
    echo ""
    echo "$token"
    echo ""
    print_warning "💡 This token will expire in about 1 hour"
    print_status "🔄 To get a new token, run this script again"
    
    return 0
}

# Function to start proxy
start_proxy() {
    print_status "Starting kubectl proxy..."
    
    # Check if proxy is already running
    if curl -s http://localhost:8001/api/v1/namespaces &> /dev/null; then
        print_warning "kubectl proxy is already running"
        return 0
    fi
    
    # Start proxy in background
    kubectl proxy &
    local proxy_pid=$!
    
    # Wait for proxy to start
    sleep 3
    
    # Check if proxy started successfully
    if curl -s http://localhost:8001/api/v1/namespaces &> /dev/null; then
        print_success "kubectl proxy started successfully (PID: $proxy_pid)"
        return 0
    else
        print_error "Failed to start kubectl proxy"
        return 1
    fi
}

# Function to show access information
show_access_info() {
    echo ""
    print_status "=== KUBERNETES DASHBOARD ACCESS ==="
    echo ""
    print_success "Dashboard URL: $DASHBOARD_URL"
    echo ""
    print_status "To access the dashboard:"
    echo "1. Open your browser and go to: $DASHBOARD_URL"
    echo "2. Select 'Token' as the authentication method"
    echo "3. Paste the token above into the token field"
    echo "4. Click 'Sign In'"
    echo ""
    print_status "What you'll see:"
    echo "- Cluster Overview (namespaces, nodes, pods)"
    echo "- Workloads (deployments, pods, services)"
    echo "- Storage (persistent volumes, claims)"
    echo "- Configuration (configMaps, secrets)"
    echo "- Your SRE Demo App resources"
    echo ""
    print_warning "Note: The kubectl proxy will continue running in the background"
    print_status "To stop it later, run: pkill -f 'kubectl proxy'"
}

# Function to cleanup
cleanup() {
    print_status "Cleaning up..."
    
    # Kill any existing kubectl proxy
    pkill -f "kubectl proxy" || true
    
    print_success "Cleanup completed"
}

# Main function
main() {
    print_status "Setting up Kubernetes Dashboard access..."
    echo ""
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check if we can access the cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot access Kubernetes cluster"
        exit 1
    fi
    
    # Check and install dashboard if needed
    check_dashboard_installation
    
    # Check dashboard status
    if ! check_dashboard_status; then
        print_error "Dashboard is not ready. Please wait a few minutes and try again."
        exit 1
    fi
    
    # Generate token
    if ! generate_token; then
        print_error "Failed to generate access token"
        exit 1
    fi
    
    # Start proxy
    if ! start_proxy; then
        print_error "Failed to start kubectl proxy"
        exit 1
    fi
    
    # Show access information
    show_access_info
    
    print_success "Kubernetes Dashboard access setup completed!"
}

# Handle script interruption
trap cleanup EXIT

# Run main function
main "$@" 