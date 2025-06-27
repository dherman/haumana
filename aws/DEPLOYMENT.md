# AWS Infrastructure Deployment Guide

Deploy Haumana's AWS infrastructure in ~25 minutes using CDK.

## Prerequisites Checklist

- [ ] **AWS Account** with appropriate permissions
- [ ] **AWS CLI** installed: `aws --version`
- [ ] **AWS CLI** configured: `aws sts get-caller-identity`
- [ ] **Node.js 18+** installed: `node --version`
- [ ] **Google OAuth 2.0 iOS Client ID** ready
  - The iOS client ID from your Google Cloud Console
  - Used by the custom authorizer to validate tokens

## Deployment Steps

### Step 1: Install AWS CDK (2 minutes)

```bash
npm install -g aws-cdk
```

Verify installation:
```bash
cdk --version
```

### Step 2: Prepare the Project (3 minutes)

```bash
# Navigate to CDK directory
cd aws/infrastructure/cdk

# Install dependencies
npm install

# Bootstrap CDK (first time only for your AWS account/region)
cdk bootstrap
```

> **Note**: CDK bootstrap creates an S3 bucket and IAM roles needed for deployment. You only need to do this once per AWS account/region.

### Step 3: Build Lambda Functions (2 minutes)

```bash
# Build the Lambda functions
cd ../../lambdas
npm install
npm run build:prod

# Build auth-sync Lambda
cd ../lambda/auth-sync
npm install
npm run build

# Return to CDK directory
cd ../../infrastructure/cdk
```

### Step 4: Build Additional Lambda Functions (1 minute)

```bash
# Build auth-sync Lambda
cd ../../lambda/auth-sync
npm install
npm run build

# Build Google token authorizer  
cd ../google-token-authorizer
npm install

# Return to CDK directory
cd ../../infrastructure/cdk
```

### Step 5: Deploy the CDK Stack (10-15 minutes)

Set your Google Client ID and deploy:

```bash
# Set environment variable
export GOOGLE_CLIENT_ID="your-google-client-id.apps.googleusercontent.com"

# Deploy the stack
cdk deploy
```

You'll be prompted to review security changes. Type **`y`** to confirm.

The deployment will:
- Create DynamoDB tables
- Set up Cognito User Pool and Identity Pool
- Deploy Lambda functions
- Configure API Gateway
- Set up IAM roles and permissions

### Step 6: Note Deployment Outputs (2 minutes)

After deployment completes, you'll see output like:

```
Outputs:
HaumanaStack.ApiEndpoint = https://YOUR_API_ID.execute-api.us-west-2.amazonaws.com/prod
HaumanaStack.UserPoolId = us-west-2_xxxxxxxxx
```

> **Note**: The stack has been simplified to remove legacy Cognito Hosted UI components. Only the User Pool (for user data storage) and API endpoints are created.

### Step 7: Save Configuration Values (2 minutes)

Save the important values for iOS app configuration:

```json
{
  "region": "us-west-2",
  "userPoolId": "YOUR_USER_POOL_ID",
  "apiEndpoint": "YOUR_API_ENDPOINT",
  "googleClientId": "YOUR_GOOGLE_CLIENT_ID"
}
```

## Verification Steps

### Test API Connectivity

```bash
# Should return 403 (expected without auth)
curl -I https://YOUR_API_ID.execute-api.us-west-2.amazonaws.com/prod/pieces
```

### Check Resources in AWS Console

1. **DynamoDB**: Look for `haumana-pieces` and `haumana-sessions` tables
2. **Cognito**: Look for `haumana-users-v2` user pool
3. **Lambda**: Look for `haumana-sync-pieces` and `haumana-sync-sessions` functions
4. **API Gateway**: Look for `haumana-api`

## Troubleshooting

### CDK Bootstrap Issues

If you see permission errors during bootstrap:
```bash
# Ensure you have AdministratorAccess or these specific permissions:
# - IAM: CreateRole, AttachRolePolicy
# - S3: CreateBucket, PutBucketPolicy
# - CloudFormation: CreateStack
```

### Deployment Failures

If deployment fails:
1. Check CloudFormation console for error details
2. Common issues:
   - Missing AWS Secrets Manager secret
   - Insufficient IAM permissions
   - Region mismatch

### Post-Deployment Issues

- **API returns 401**: Check that Google OAuth redirect URI is configured correctly
- **Lambda timeouts**: Increase timeout in CDK stack (default is 30s)
- **DynamoDB throttling**: Switch to on-demand billing mode

## Updating the Stack

To update after making changes:

```bash
# See what will change
cdk diff

# Deploy updates
cdk deploy
```

## Destroying the Stack

To remove all AWS resources:

```bash
cdk destroy
```

⚠️ **Warning**: This will delete all data in DynamoDB tables!

## Next Steps

1. Update iOS app configuration with the deployment outputs
2. Test sync functionality
3. Set up monitoring with CloudWatch alarms (see [docs/cloudwatch-alarms-setup.md](infrastructure/docs/cloudwatch-alarms-setup.md))
4. Configure budget alerts (see [docs/create-haumana-budget.md](infrastructure/docs/create-haumana-budget.md))

## Estimated Time: 20-25 minutes total

- Prerequisites check: 2 minutes
- CDK installation: 2 minutes  
- Project setup: 3 minutes
- Lambda builds: 2 minutes
- Secrets setup: 2 minutes
- CDK deployment: 10-15 minutes
- Configuration save: 2 minutes
- Verification: 2 minutes