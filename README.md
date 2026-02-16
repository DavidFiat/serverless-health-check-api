# Serverless Health Check API with CI/CD

DevOps project: Serverless Health Check API with automated deployment pipeline on AWS.

## Table of Contents
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
- [CI/CD Pipeline](#cicd-pipeline)
- [Deployment](#deployment)
- [Testing](#testing)
- [Design Decisions](#design-decisions)

## Architecture

This project implements a serverless health check API with the following AWS components:

- **API Gateway**: REST API with API key authentication and throttling
- **Lambda Function**: Python 3.11 function in VPC with input validation
- **DynamoDB**: NoSQL database with KMS Customer Managed Key encryption
- **VPC**: Private subnets with DynamoDB VPC endpoint
- **CloudWatch**: Centralized logging
- **IAM**: Least-privilege roles (no wildcards)
- **KMS**: Customer Managed Key with automatic rotation

### Resource Naming Convention
All resources follow: `{environment}-{resource}-{name}`

Examples:
- `staging-requests-db`
- `staging-health-check-function`
- `prod-health-check-api`

## Prerequisites

### Required Tools
- **AWS Account** with appropriate permissions
- **AWS CLI** (v2.x) - [Install Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **Terraform** (v1.0+) - [Install Guide](https://developer.hashicorp.com/terraform/downloads)
- **Git** - [Install Guide](https://git-scm.com/downloads)

### AWS Permissions Required
Your IAM user needs permissions for:
- Lambda, API Gateway, DynamoDB, IAM, CloudWatch, KMS

## Setup Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/DavidFiat/serverless-health-check-api.git
cd serverless-health-check-api
```

### 2. Configure AWS Credentials

#### Option A: AWS CLI Configuration (Recommended for local testing)
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: us-east-1
# Default output format: json
```

#### Option B: GitHub Secrets (Required for CI/CD)
1. Go to your GitHub repository
2. Navigate to: **Settings → Secrets and variables → Actions**
3. Add the following secrets:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
   - `AWS_REGION`: `us-east-1`

### 3. Configure GitHub Environments (Required for CI/CD)

GitHub Environments provide deployment protection rules and are required for the production deployment approval workflow.

#### Setup Production Environment
1. Go to your GitHub repository
2. Navigate to: **Settings → Environments**
3. Click **New environment**
4. Name it: `production`
5. Under **Deployment protection rules**:
   - Check **Required reviewers**
   - Add yourself (or team members) as reviewers
   - Optionally set **Wait timer** (e.g., 5 minutes)
6. Click **Save protection rules**

#### Setup Staging Environment
1. Click **New environment**
2. Name it: `staging`
3. No protection rules needed (allows auto-deploy)
4. Click **Create environment**

**Why this matters**: 
- The `production` environment requires manual approval before any deployment
- The `staging` environment deploys automatically on push to staging branch
- This adds an extra safety layer preventing accidental production deployments

### 4. Create Staging Branch (Required for CI/CD)

The CI/CD pipeline requires a `staging` branch for automatic deployments:

```bash
git checkout -b staging
git push origin staging
```

**Note**: Push to `staging` branch triggers automatic deployment to staging environment.

### 5. Local Deployment (Optional)

#### Deploy Staging Environment
```bash
cd terraform
terraform init
terraform plan -var-file="staging.tfvars"
terraform apply -var-file="staging.tfvars"
```

#### Deploy Production Environment
```bash
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"
```

## CI/CD Pipeline

### Pipeline Overview

The GitHub Actions pipeline consists of three main jobs:

#### 1. Security Scanning
- **IaC Security**: Runs `tfsec` to scan Terraform code for security issues
- **Dependency Scanning**: Runs `safety` to check Python dependencies for vulnerabilities
- Executes on every push and pull request

#### 2. Deploy to Staging
- **Trigger**: Automatic on push to `staging` branch only
- **Steps**:
  1. Checkout code
  2. Setup Terraform
  3. Configure AWS credentials
  4. Run `terraform init`
  5. Run `terraform plan` with staging.tfvars
  6. Run `terraform apply`
  7. Test the deployed endpoint

#### 3. Deploy to Production
- **Trigger**: Manual approval required (workflow_dispatch)
- **Protection**: Requires manual approval in GitHub environment settings
- **Steps**: Same as staging but uses prod.tfvars

### Pipeline Workflow
```
Push to staging branch
    ↓
Security Scan (tfsec + safety)
    ↓
Deploy to Staging (automatic)

Manual trigger for Production
    ↓
Security Scan (tfsec + safety)
    ↓
Deploy to Production (manual approval)
```

## Deployment

### Automatic Deployment (Staging)

Push to the `staging` branch:
```bash
git add .
git commit -m "your changes"
git push origin staging
```

The pipeline will automatically:
1. Run security scans
2. Deploy to staging environment
3. Test the endpoint

### Manual Deployment (Production)

#### Step 1: Trigger the Workflow
1. Go to **Actions** tab in GitHub
2. Select **Deploy Infrastructure** workflow
3. Click **Run workflow** button (top right)
4. Select `prod` from the environment dropdown
5. Click **Run workflow** to confirm

#### Step 2: Approve the Deployment
1. Wait for the workflow to reach the production job
2. You'll see a yellow "Waiting" status
3. Click **Review deployments**
4. Check the `production` environment
5. Click **Approve and deploy**

#### Step 3: Monitor Deployment
- Watch the Terraform apply logs in real-time
- Deployment takes ~3-5 minutes
- Once complete, test the production endpoint

**Note**: Only users configured as reviewers in the production environment can approve deployments.

## Testing

### Test the Health Endpoint

After deployment, get your API endpoint:
```bash
cd terraform
terraform output api_endpoint
```

#### Test with cURL (POST with API Key)
```bash
curl -X POST "https://YOUR_API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_API_KEY" \
  -d '{"payload": "Hello from health check"}'
```

To get your API key:
```bash
cd terraform
terraform output -raw api_key
```

Expected response:
```json
{
  "status": "healthy",
  "message": "Request processed and saved.",
  "id": "uuid-here"
}
```

#### Test with cURL (GET)
```bash
curl -X GET "https://YOUR_API_ENDPOINT/health" \
  -H "Content-Type: application/json" \
  -d '{"payload": "test"}'
```

#### Test Input Validation (Should return 400)
```bash
curl -X POST "https://YOUR_API_ENDPOINT/health" \
  -H "Content-Type: application/json" \
  -d '{"invalid": "field"}'
```

Expected response:
```json
{
  "error": "Missing required field: payload"
}
```

### Verify in AWS Console

1. **DynamoDB**: Check `staging-requests-db` table for saved items
2. **CloudWatch**: View logs at `/aws/lambda/staging-health-check-function`
3. **API Gateway**: Monitor throttling metrics

## Design Decisions

### Security Implementations

#### Encryption Everywhere
- DynamoDB table uses Customer Managed Key (CMK) in KMS
- Automatic key rotation enabled
- Enhanced security over AWS-managed keys

#### Least Privilege IAM
- Lambda execution role has only required permissions:
  - `dynamodb:PutItem` (scoped to specific table)
  - CloudWatch Logs (scoped to specific log group)
- **No wildcards (*) used** except where mandatory

#### Input Validation
- Lambda validates that `payload` field exists in request body
- Returns 400 error if validation fails
- Prevents invalid data from reaching DynamoDB

#### DDoS Prevention
- API Gateway throttling configured:
  - Staging: 100 requests/sec, burst 50
  - Production: 1000 requests/sec, burst 500

#### IaC Security Scanning
- `tfsec` scans Terraform code before deployment
- Catches security misconfigurations early

#### Dependency Scanning
- `safety` checks Python dependencies for known vulnerabilities
- Runs on every pipeline execution

### Infrastructure Choices

#### Why HTTP API (not REST API)?
- Simpler configuration
- Lower cost (~70% cheaper)
- Built-in throttling support
- Sufficient for this use case

#### Why DynamoDB?
- Serverless (no server management)
- Auto-scaling
- Built-in encryption
- Pay-per-request pricing

#### Why Python 3.11?
- Latest stable runtime
- Better performance than 3.9/3.10
- Native AWS SDK (boto3)

### Multi-Environment Strategy

- **Separate tfvars files**: `staging.tfvars` and `prod.tfvars`
- **Different resource limits**: Production has higher memory and throttling
- **Isolated resources**: Each environment has its own DynamoDB table, Lambda, API

### CI/CD Strategy

- **Branch separation**: `staging` branch deploys to staging, `main` is production-ready code
- **Atomic commits**: Each commit represents a logical unit of work
- **Security-first**: Scans run before any deployment
- **Staging isolation**: Only staging branch triggers staging deployment
- **Production protection**: Manual approval required for prod

## Project Structure

```
.
├── .github/
│   └── workflows/
│       └── deploy.yml           # CI/CD pipeline
├── lambda/
│   ├── index.py                 # Lambda function code
│   ├── requirements.txt         # Python dependencies
│   └── README.md
├── terraform/
│   ├── main.tf                  # Main configuration
│   ├── provider.tf              # AWS provider
│   ├── variables.tf             # Input variables
│   ├── outputs.tf               # Output values
│   ├── dynamodb.tf              # DynamoDB table
│   ├── iam.tf                   # IAM roles and policies
│   ├── lambda.tf                # Lambda function
│   ├── api_gateway.tf           # API Gateway
│   ├── staging.tfvars           # Staging environment vars
│   └── prod.tfvars              # Production environment vars
├── .gitignore
└── README.md
```

## Troubleshooting

### Terraform State Lock
If you see a state lock error:
```bash
terraform force-unlock LOCK_ID
```

### Lambda Deployment Package Too Large
The current setup packages only `index.py`. If you add dependencies:
```bash
cd lambda
pip install -r requirements.txt -t .
zip -r ../terraform/lambda_function.zip .
```

### API Gateway 403 Error
Check that Lambda permission allows API Gateway to invoke it:
```bash
aws lambda get-policy --function-name staging-health-check-function
```

## Requirements Checklist

### Core Requirements
- Infrastructure as Code (Terraform)
- Multi-environment setup (staging/prod)
- Resource naming convention (`env-resource-name`)
- DynamoDB with SSE encryption
- API Gateway with throttling
- Lambda function (Python)
- IAM roles with least privilege
- CloudWatch logging
- Input validation (payload field required)
- CI/CD pipeline (GitHub Actions)
- IaC security scanning (tfsec)
- Dependency scanning (safety)

### Bonus Features Implemented
- Customer Managed Key (KMS) with automatic rotation
- Lambda in dedicated VPC with private subnets
- DynamoDB VPC endpoint for secure access
- API Key authentication with usage plans and rate limiting

## Author

**Jhoan David**

Project submitted as part of DevOps technical assessment.

## License

This project is for educational and assessment purposes.
