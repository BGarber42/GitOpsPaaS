#!/bin/bash

# GitOps PaaS Deployment Script
# This script helps deploy the infrastructure and configure GitHub secrets

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

# Check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    print_success "All prerequisites are installed"
}

# Configure AWS credentials
configure_aws() {
    print_status "Configuring AWS credentials..."
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_warning "AWS credentials not configured. Please run 'aws configure' first."
        read -p "Do you want to configure AWS now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            aws configure
        else
            print_error "AWS credentials are required to proceed."
            exit 1
        fi
    fi
    
    print_success "AWS credentials configured"
}

# Deploy infrastructure with Terraform
deploy_infrastructure() {
    print_status "Deploying infrastructure with Terraform..."
    
    cd infrastructure
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Plan the deployment
    print_status "Planning Terraform deployment..."
    terraform plan -out=tfplan
    
    # Apply the deployment
    print_status "Applying Terraform deployment..."
    terraform apply tfplan
    
    # Get outputs
    print_status "Getting Terraform outputs..."
    ECR_REPOSITORY_URI=$(terraform output -raw ecr_repository_url)
    ECS_CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
    ECS_SERVICE_NAME=$(terraform output -raw ecs_service_name)
    ALB_DNS_NAME=$(terraform output -raw alb_dns_name)
    
    cd ..
    
    print_success "Infrastructure deployed successfully"
    print_status "ECR Repository: $ECR_REPOSITORY_URI"
    print_status "ECS Cluster: $ECS_CLUSTER_NAME"
    print_status "ECS Service: $ECS_SERVICE_NAME"
    print_status "Load Balancer: $ALB_DNS_NAME"
}

# Configure GitHub secrets
configure_github_secrets() {
    print_status "Configuring GitHub secrets..."
    
    # Get AWS credentials
    AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
    AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
    AWS_REGION=$(aws configure get region)
    
    print_warning "Please configure the following secrets in your GitHub repository:"
    echo
    echo "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
    echo "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"
    echo "AWS_REGION=$AWS_REGION"
    echo "ECR_REPOSITORY_URI=$ECR_REPOSITORY_URI"
    echo "ECS_CLUSTER_NAME=$ECS_CLUSTER_NAME"
    echo "ECS_SERVICE_NAME=$ECS_SERVICE_NAME"
    echo
    
    print_status "To configure these secrets:"
    print_status "1. Go to your GitHub repository"
    print_status "2. Navigate to Settings > Secrets and variables > Actions"
    print_status "3. Add each secret with the values shown above"
}

# Test the deployment
test_deployment() {
    print_status "Testing the deployment..."
    
    # Wait for the service to be stable
    print_status "Waiting for ECS service to be stable..."
    aws ecs wait services-stable \
        --cluster "$ECS_CLUSTER_NAME" \
        --services "$ECS_SERVICE_NAME"
    
    # Test the health endpoint
    print_status "Testing health endpoint..."
    HEALTH_URL="http://$ALB_DNS_NAME/health"
    
    for i in {1..30}; do
        if curl -f "$HEALTH_URL" &> /dev/null; then
            print_success "Application is healthy and responding"
            print_status "Health check URL: $HEALTH_URL"
            print_status "Application URL: http://$ALB_DNS_NAME"
            return 0
        fi
        print_status "Waiting for application to be ready... (attempt $i/30)"
        sleep 10
    done
    
    print_error "Application failed to become healthy"
    return 1
}

# Main deployment function
main() {
    print_status "Starting GitOps PaaS deployment..."
    
    check_prerequisites
    configure_aws
    deploy_infrastructure
    configure_github_secrets
    
    read -p "Do you want to test the deployment now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        test_deployment
    fi
    
    print_success "Deployment completed successfully!"
    print_status "Next steps:"
    print_status "1. Configure GitHub secrets as shown above"
    print_status "2. Push code to the main branch to trigger deployment"
    print_status "3. Monitor the deployment in GitHub Actions"
}

# Run main function
main "$@" 