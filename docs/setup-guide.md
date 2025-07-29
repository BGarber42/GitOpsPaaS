# Setup Guide for Serverless GitOps PaaS

## Prerequisites

Before starting the deployment, ensure you have the following tools installed:

### Required Tools
- **Terraform** (v1.0 or later)
- **AWS CLI** (v2.0 or later)
- **Docker** (v20.0 or later)
- **Git** (v2.0 or later)

### AWS Account Requirements
- AWS account with appropriate permissions
- IAM user with programmatic access
- Sufficient AWS credits or billing setup

## Step 1: Clone and Setup Repository

```bash
# Clone the repository
git clone <your-repository-url>
cd ServerlessGitOpsPaaS

# Make deployment scripts executable (Linux/Mac)
chmod +x scripts/deploy.sh
```

## Step 2: Configure AWS Credentials

### Option A: AWS CLI Configuration
```bash
aws configure
```
Enter your:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., us-east-1)
- Default output format (json)

### Option B: Environment Variables
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

## Step 3: Deploy Infrastructure

### Using the Deployment Script (Recommended)

#### For Linux/Mac:
```bash
./scripts/deploy.sh
```

#### For Windows PowerShell:
```powershell
.\scripts\deploy.ps1
```

### Manual Deployment
```bash
# Navigate to infrastructure directory
cd infrastructure

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the deployment
terraform apply
```

## Step 4: Configure GitHub Secrets

After successful infrastructure deployment, configure the following secrets in your GitHub repository:

### Required Secrets
1. Go to your GitHub repository
2. Navigate to **Settings** > **Secrets and variables** > **Actions**
3. Add the following repository secrets:

| Secret Name | Value Source |
|-------------|--------------|
| `AWS_ACCESS_KEY_ID` | Your AWS Access Key ID |
| `AWS_SECRET_ACCESS_KEY` | Your AWS Secret Access Key |
| `AWS_REGION` | Your AWS region (e.g., us-east-1) |
| `ECR_REPOSITORY_URI` | From Terraform output |
| `ECS_CLUSTER_NAME` | From Terraform output |
| `ECS_SERVICE_NAME` | From Terraform output |

### Getting Secret Values
After running the deployment script, it will display the required values. Alternatively, you can get them from Terraform:

```bash
cd infrastructure
terraform output
```

## Step 5: Test the Deployment

### Option A: Using the Deployment Script
The deployment script includes an option to test the deployment automatically.

### Option B: Manual Testing
```bash
# Get the load balancer DNS name
ALB_DNS=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[0].DNSName' --output text)

# Test the health endpoint
curl http://$ALB_DNS/health

# Test the main application
curl http://$ALB_DNS/
```

## Step 6: Trigger Your First Deployment

### Push to Main Branch
```bash
# Make a change to trigger deployment
echo "# Updated README" >> README.md
git add .
git commit -m "Trigger first deployment"
git push origin main
```

### Monitor the Deployment
1. Go to your GitHub repository
2. Navigate to **Actions** tab
3. Monitor the deployment workflow

## Step 7: Verify Deployment

### Check Application Status
```bash
# Get application URL
ALB_DNS=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[0].DNSName' --output text)
echo "Application URL: http://$ALB_DNS"
echo "Health Check: http://$ALB_DNS/health"
```

### Test Application Endpoints
```bash
# Health check
curl http://$ALB_DNS/health

# Application info
curl http://$ALB_DNS/info

# Status endpoint
curl http://$ALB_DNS/status

# Echo endpoint
curl -X POST http://$ALB_DNS/api/echo \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello GitOps!"}'
```

## Troubleshooting

### Common Issues

#### 1. Terraform Errors
```bash
# Clean up and retry
cd infrastructure
terraform destroy
terraform init
terraform apply
```

#### 2. AWS Credentials Issues
```bash
# Verify credentials
aws sts get-caller-identity

# Reconfigure if needed
aws configure
```

#### 3. Docker Build Issues
```bash
# Test Docker build locally
cd sample-app
docker build -t test-app .
docker run -p 5000:5000 test-app
```

#### 4. ECS Service Issues
```bash
# Check service status
aws ecs describe-services \
  --cluster gitops-paas-dev \
  --services gitops-paas-dev

# Check task logs
aws logs describe-log-groups --log-group-name-prefix "/ecs/gitops-paas-dev"
```

### Debugging GitHub Actions

#### 1. Check Workflow Logs
- Go to GitHub repository > Actions
- Click on the failed workflow
- Review the logs for specific errors

#### 2. Common GitHub Actions Issues
- **ECR Login Failed**: Check AWS credentials
- **Build Failed**: Check Dockerfile syntax
- **Deployment Failed**: Check ECS service configuration

#### 3. Security Scan Failures
- Review Trivy scan results in GitHub Security tab
- Update vulnerable dependencies
- Re-run the workflow

## Monitoring and Maintenance

### CloudWatch Monitoring
```bash
# View application logs
aws logs tail /ecs/gitops-paas-dev --follow

# Check ECS metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=gitops-paas-dev \
  --start-time $(date -d '1 hour ago' --iso-8601) \
  --end-time $(date --iso-8601) \
  --period 300 \
  --statistics Average
```

### Cost Monitoring
```bash
# Check AWS costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost
```

## Scaling and Optimization

### Auto-scaling Configuration
The infrastructure includes auto-scaling based on:
- CPU utilization (70% threshold)
- Memory utilization (80% threshold)

### Manual Scaling
```bash
# Update service desired count
aws ecs update-service \
  --cluster gitops-paas-dev \
  --service gitops-paas-dev \
  --desired-count 3
```

### Resource Optimization
```bash
# Update task definition for different resource allocation
cd infrastructure
terraform apply -var="task_cpu=512" -var="task_memory=1024"
```

## Security Best Practices

### 1. IAM Roles
- Use least privilege access
- Regularly rotate access keys
- Monitor IAM activity

### 2. Network Security
- VPC isolation
- Security group restrictions
- Private subnets for application tasks

### 3. Container Security
- Regular vulnerability scans
- Multi-stage Docker builds
- Non-root user execution

## Backup and Recovery

### Terraform State Backup
```bash
# Backup Terraform state
cd infrastructure
terraform state pull > terraform-state-backup.json
```

### ECR Image Backup
```bash
# List images in ECR
aws ecr describe-images --repository-name gitops-paas-dev
```

## Cleanup

### Destroy Infrastructure
```bash
cd infrastructure
terraform destroy
```

### Clean Up Resources
```bash
# Delete ECR repository
aws ecr delete-repository --repository-name gitops-paas-dev --force

# Delete CloudWatch log group
aws logs delete-log-group --log-group-name /ecs/gitops-paas-dev
```

## Support and Resources

### Documentation
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

### Community
- GitHub Issues for bug reports
- Stack Overflow for questions
- AWS Support for infrastructure issues

## Next Steps

After successful deployment:

1. **Customize the Application**: Modify the Flask app in `sample-app/`
2. **Add More Services**: Extend the infrastructure for additional applications
3. **Implement Monitoring**: Add CloudWatch dashboards and alerts
4. **Security Hardening**: Implement additional security measures
5. **Cost Optimization**: Monitor and optimize resource usage

## Success Metrics

Monitor these metrics to ensure successful deployment:

- **Deployment Time**: < 5 minutes from push to production
- **Application Availability**: > 99.9% uptime
- **Cost Efficiency**: < $100/month for development environment
- **Security**: Zero critical vulnerabilities in container scans
- **Performance**: < 200ms response time for health checks 