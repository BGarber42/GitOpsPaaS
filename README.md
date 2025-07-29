# Serverless GitOps PaaS

A fully automated, serverless platform on AWS that deploys containerized web applications from a simple git push. Built with cost-efficiency and minimal operational overhead in mind.

## Architecture Overview

This project implements a GitOps workflow where:
1. Developers push code to the main branch
2. GitHub Actions automatically builds and scans Docker images
3. Images are pushed to AWS ECR
4. ECS Fargate services are automatically updated with new deployments

## Key Features

- **Serverless**: Uses AWS Fargate for compute (no EC2 management)
- **Cost-Effective**: Leverages free-tier eligible services
- **Automated**: Full CI/CD pipeline with GitHub Actions
- **Secure**: Container vulnerability scanning with Trivy
- **Infrastructure as Code**: Complete Terraform implementation

## Technology Stack

- **Cloud Provider**: AWS
- **Container Orchestration**: AWS ECS on Fargate
- **Container Registry**: AWS ECR
- **CI/CD**: GitHub Actions
- **Infrastructure as Code**: Terraform
- **Containerization**: Docker
- **Sample Application**: Python Flask API

## Project Structure

```
├── .github/
│   └── workflows/
│       └── deploy.yml
├── infrastructure/
│   ├── main.tf
│   ├── ecs_service.tf
│   ├── variables.tf
│   └── outputs.tf
├── sample-app/
│   ├── app.py
│   ├── requirements.txt
│   └── Dockerfile
├── docs/
│   └── architecture.md
└── README.md
```

## Quick Start

1. **Clone and Setup**:
   ```bash
   git clone <repository-url>
   cd ServerlessGitOpsPaaS
   ```

2. **Configure AWS Credentials**:
   ```bash
   aws configure
   ```

3. **Deploy Infrastructure**:
   ```bash
   cd infrastructure
   terraform init
   terraform plan
   terraform apply
   ```

4. **Configure GitHub Secrets**:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION`
   - `ECR_REPOSITORY_URI`
   - `ECS_CLUSTER_NAME`
   - `ECS_SERVICE_NAME`

5. **Push to Main Branch**:
   ```bash
   git push origin main
   ```

## Cost Optimization

- Uses AWS Fargate (pay-per-use, no idle costs)
- Leverages AWS free tier where possible
- Minimal resource allocation for development
- Auto-scaling based on demand

## Security Features

- Container vulnerability scanning with Trivy
- IAM roles with least privilege access
- VPC isolation with private subnets
- HTTPS-only communication

## Monitoring and Logging

- CloudWatch logs for application monitoring
- ECS service metrics
- GitHub Actions workflow status tracking

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Push to trigger the deployment pipeline
5. Submit a pull request

## License

MIT License - see LICENSE file for details 