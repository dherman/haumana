# Fixing AWS IAM Permissions for CDK

Your current user `cli` only has:
- IAMFullAccess
- AWSLambda_FullAccess

But CDK needs additional permissions to create and manage infrastructure.

## Option 1: Add Individual AWS Managed Policies (More Secure)

Add these specific policies for CDK deployment:

```bash
# CloudFormation access (required for CDK)
aws iam attach-user-policy \
  --user-name cli \
  --policy-arn arn:aws:iam::aws:policy/AWSCloudFormationFullAccess

# S3 access (CDK stores assets here)
aws iam attach-user-policy \
  --user-name cli \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

# DynamoDB access (for your tables)
aws iam attach-user-policy \
  --user-name cli \
  --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess

# API Gateway access
aws iam attach-user-policy \
  --user-name cli \
  --policy-arn arn:aws:iam::aws:policy/AmazonAPIGatewayAdministrator

# Cognito access
aws iam attach-user-policy \
  --user-name cli \
  --policy-arn arn:aws:iam::aws:policy/AmazonCognitoPowerUser

# Secrets Manager access (for reading the Google client secret)
aws iam attach-user-policy \
  --user-name cli \
  --policy-arn arn:aws:iam::aws:policy/SecretsManagerReadWrite

# ECR access (CDK uses this for Lambda containers)
aws iam attach-user-policy \
  --user-name cli \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess

# SSM Parameter Store (CDK bootstrap uses this)
aws iam attach-user-policy \
  --user-name cli \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMFullAccess
```

## Option 2: Temporary Administrator Access (Easiest)

For initial setup, you could temporarily grant full admin access:

```bash
aws iam attach-user-policy \
  --user-name cli \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

**Important**: Remove this after deployment for security:
```bash
aws iam detach-user-policy \
  --user-name cli \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

## Option 3: Create a Custom CDK Deployment Policy

Create a policy with only the permissions CDK needs:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudformation:*",
        "s3:*",
        "iam:*",
        "lambda:*",
        "dynamodb:*",
        "cognito:*",
        "cognito-idp:*",
        "cognito-identity:*",
        "apigateway:*",
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "ssm:*",
        "ecr:*",
        "ecr-public:*",
        "sts:AssumeRole"
      ],
      "Resource": "*"
    }
  ]
}
```

Save this as `cdk-deploy-policy.json` and create the policy:

```bash
aws iam create-policy \
  --policy-name CDKDeploymentPolicy \
  --policy-document file://cdk-deploy-policy.json

# Then attach it
aws iam attach-user-policy \
  --user-name cli \
  --policy-arn arn:aws:iam::248619912908:policy/CDKDeploymentPolicy
```

## What CDK Bootstrap Does

CDK bootstrap creates:
1. An S3 bucket for storing deployment assets
2. An ECR repository for Docker images (if using Lambda containers)
3. IAM roles for CloudFormation deployments
4. SSM parameters to track bootstrap version

That's why it needs broad permissions for the initial setup.

## Recommendation

For now, use **Option 1** (add individual policies). This gives you the permissions you need without full admin access.

After you run these commands, you should be able to run `cdk bootstrap` successfully.