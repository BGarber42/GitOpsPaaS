# GitOps PaaS Deployment Script for PowerShell
# This script helps deploy the infrastructure and configure GitHub secrets

param(
    [switch]$SkipPrerequisites,
    [switch]$SkipTest
)

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check if required tools are installed
function Test-Prerequisites {
    Write-Status "Checking prerequisites..."
    
    $tools = @("terraform", "aws", "docker")
    $missing = @()
    
    foreach ($tool in $tools) {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
            $missing += $tool
        }
    }
    
    if ($missing.Count -gt 0) {
        Write-Error "Missing required tools: $($missing -join ', ')"
        Write-Error "Please install the missing tools before proceeding."
        exit 1
    }
    
    Write-Success "All prerequisites are installed"
}

# Configure AWS credentials
function Test-AwsCredentials {
    Write-Status "Checking AWS credentials..."
    
    try {
        $identity = aws sts get-caller-identity 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "AWS credentials are configured"
            return $true
        }
    }
    catch {
        # Continue to prompt
    }
    
    Write-Warning "AWS credentials not configured."
    $configure = Read-Host "Do you want to configure AWS now? (y/n)"
    if ($configure -eq 'y' -or $configure -eq 'Y') {
        aws configure
        return $true
    }
    else {
        Write-Error "AWS credentials are required to proceed."
        exit 1
    }
}

# Deploy infrastructure with Terraform
function Deploy-Infrastructure {
    Write-Status "Deploying infrastructure with Terraform..."
    
    Push-Location infrastructure
    
    try {
        # Initialize Terraform
        Write-Status "Initializing Terraform..."
        terraform init
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform init failed"
        }
        
        # Plan the deployment
        Write-Status "Planning Terraform deployment..."
        terraform plan -out=tfplan
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform plan failed"
        }
        
        # Apply the deployment
        Write-Status "Applying Terraform deployment..."
        terraform apply tfplan
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform apply failed"
        }
        
        # Get outputs
        Write-Status "Getting Terraform outputs..."
        $script:ECR_REPOSITORY_URI = terraform output -raw ecr_repository_url
        $script:ECS_CLUSTER_NAME = terraform output -raw ecs_cluster_name
        $script:ECS_SERVICE_NAME = terraform output -raw ecs_service_name
        $script:ALB_DNS_NAME = terraform output -raw alb_dns_name
        
        Write-Success "Infrastructure deployed successfully"
        Write-Status "ECR Repository: $ECR_REPOSITORY_URI"
        Write-Status "ECS Cluster: $ECS_CLUSTER_NAME"
        Write-Status "ECS Service: $ECS_SERVICE_NAME"
        Write-Status "Load Balancer: $ALB_DNS_NAME"
    }
    finally {
        Pop-Location
    }
}

# Configure GitHub secrets
function Show-GitHubSecrets {
    Write-Status "Configuring GitHub secrets..."
    
    # Get AWS credentials
    $AWS_ACCESS_KEY_ID = aws configure get aws_access_key_id
    $AWS_SECRET_ACCESS_KEY = aws configure get aws_secret_access_key
    $AWS_REGION = aws configure get region
    
    Write-Warning "Please configure the following secrets in your GitHub repository:"
    Write-Host ""
    Write-Host "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
    Write-Host "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"
    Write-Host "AWS_REGION=$AWS_REGION"
    Write-Host "ECR_REPOSITORY_URI=$ECR_REPOSITORY_URI"
    Write-Host "ECS_CLUSTER_NAME=$ECS_CLUSTER_NAME"
    Write-Host "ECS_SERVICE_NAME=$ECS_SERVICE_NAME"
    Write-Host ""
    
    Write-Status "To configure these secrets:"
    Write-Status "1. Go to your GitHub repository"
    Write-Status "2. Navigate to Settings > Secrets and variables > Actions"
    Write-Status "3. Add each secret with the values shown above"
}

# Test the deployment
function Test-Deployment {
    Write-Status "Testing the deployment..."
    
    # Wait for the service to be stable
    Write-Status "Waiting for ECS service to be stable..."
    aws ecs wait services-stable --cluster $ECS_CLUSTER_NAME --services $ECS_SERVICE_NAME
    
    # Test the health endpoint
    Write-Status "Testing health endpoint..."
    $HEALTH_URL = "http://$ALB_DNS_NAME/health"
    
    for ($i = 1; $i -le 30; $i++) {
        try {
            $response = Invoke-WebRequest -Uri $HEALTH_URL -UseBasicParsing -TimeoutSec 10
            if ($response.StatusCode -eq 200) {
                Write-Success "Application is healthy and responding"
                Write-Status "Health check URL: $HEALTH_URL"
                Write-Status "Application URL: http://$ALB_DNS_NAME"
                return $true
            }
        }
        catch {
            # Continue to next attempt
        }
        
        Write-Status "Waiting for application to be ready... (attempt $i/30)"
        Start-Sleep -Seconds 10
    }
    
    Write-Error "Application failed to become healthy"
    return $false
}

# Main deployment function
function Start-Deployment {
    Write-Status "Starting GitOps PaaS deployment..."
    
    if (-not $SkipPrerequisites) {
        Test-Prerequisites
    }
    
    Test-AwsCredentials
    Deploy-Infrastructure
    Show-GitHubSecrets
    
    if (-not $SkipTest) {
        $test = Read-Host "Do you want to test the deployment now? (y/n)"
        if ($test -eq 'y' -or $test -eq 'Y') {
            Test-Deployment
        }
    }
    
    Write-Success "Deployment completed successfully!"
    Write-Status "Next steps:"
    Write-Status "1. Configure GitHub secrets as shown above"
    Write-Status "2. Push code to the main branch to trigger deployment"
    Write-Status "3. Monitor the deployment in GitHub Actions"
}

# Run main function
Start-Deployment 