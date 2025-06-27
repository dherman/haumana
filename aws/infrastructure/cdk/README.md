# Haumana AWS CDK Infrastructure

This CDK application deploys all AWS infrastructure for Haumana's cloud sync functionality.

## What Gets Deployed

- **DynamoDB Tables**: `haumana-pieces` and `haumana-sessions` with indexes
- **Cognito User Pool**: For user data storage only (not authentication)
- **Lambda Functions**: 
  - Sync functions for pieces and sessions
  - Google token authorizer for API authentication
  - Auth sync function to store user data
- **API Gateway**: REST API with custom Google token authorization
- **IAM Roles**: All necessary permissions

## Prerequisites

1. AWS CLI configured with credentials
2. Node.js 18+ and npm
3. Google OAuth 2.0 iOS Client ID (for the custom authorizer)
4. AWS CDK CLI: `npm install -g aws-cdk`

## Setup Instructions

### 1. Install Dependencies

```bash
cd aws/infrastructure/cdk
npm install
```

### 2. Bootstrap CDK (First Time Only)

```bash
npm run bootstrap
```

### 3. Build Lambda Functions

```bash
# Build sync lambdas
cd ../../lambdas
npm install
npm run build:prod

# Build auth-sync lambda
cd ../lambda/auth-sync
npm install
npm run build

# Build Google token authorizer
cd ../google-token-authorizer
npm install

# Return to CDK directory
cd ../../infrastructure/cdk
```

### 4. Deploy Stack

Option A: Using environment variable
```bash
export GOOGLE_CLIENT_ID="your-google-client-id.apps.googleusercontent.com"
npm run deploy
```

Option B: Using CDK context
```bash
npm run deploy -- -c googleClientId=your-google-client-id.apps.googleusercontent.com
```

### 5. Note the Outputs

After deployment, CDK will output:
- User Pool ID (for user data storage)
- API Endpoint URL

## Customization

### Change Region
Edit `app.ts`:
```typescript
env: {
  region: 'us-east-1', // Change from us-west-2
}
```

### Change Table Names
Edit `haumana-stack.ts`:
```typescript
tableName: 'my-custom-pieces-table',
```

### Add Custom Attributes
Edit the User Pool configuration:
```typescript
customAttributes: {
  organization: new cognito.StringAttribute({
    minLen: 1,
    maxLen: 100,
  }),
}
```

## Managing the Stack

### View Changes Before Deploying
```bash
npm run diff
```

### Update Stack
```bash
npm run deploy
```

### Destroy Stack (Warning: Deletes Everything!)
```bash
npm run destroy
```

## Cost Optimization

The stack uses:
- DynamoDB on-demand pricing
- Lambda pay-per-invocation
- API Gateway pay-per-request
- Cognito free tier (up to 50,000 MAUs)

Estimated cost for 100 active users: ~$10-20/month

## Troubleshooting

### "Stack already exists"
The stack name must be unique in your account/region. Either:
- Delete the existing stack
- Change the stack name in `app.ts`

### "Bootstrap stack required"
Run `npm run bootstrap` first

### "Credentials not found"
Ensure AWS CLI is configured: `aws configure`

### API Authorization Not Working
1. Verify Google iOS Client ID is correct in the authorizer
2. Check that the iOS app is sending Google ID tokens
3. Review CloudWatch logs for the authorizer Lambda

## Next Steps

1. Update iOS app configuration:
   - Set API endpoint in AppConstants.swift
   - Ensure Google Sign-In is configured with iOS client ID

2. Test the sync flow:
   - Sign in with Google
   - Create some pieces
   - Verify they sync to DynamoDB

3. Monitor CloudWatch logs for any errors