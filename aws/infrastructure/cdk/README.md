# Haumana AWS CDK Infrastructure

This CDK application deploys all AWS infrastructure for Haumana's cloud sync functionality.

## What Gets Deployed

- **DynamoDB Tables**: `haumana-pieces` and `haumana-sessions` with indexes
- **Cognito User Pool**: With Google federation configured
- **Cognito Identity Pool**: For AWS credentials
- **Lambda Functions**: TypeScript functions for sync operations
- **API Gateway**: REST API with Cognito authorization
- **IAM Roles**: All necessary permissions

## Prerequisites

1. AWS CLI configured with credentials
2. Node.js 18+ and npm
3. Google OAuth 2.0 credentials (Client ID and Secret)
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
cd ../../lambdas
npm install
npm run build:prod
cd ../infrastructure/cdk
```

### 4. Deploy Stack

Option A: Using environment variables
```bash
export GOOGLE_CLIENT_ID="your-google-client-id.apps.googleusercontent.com"
export GOOGLE_CLIENT_SECRET="your-google-client-secret"
npm run deploy
```

Option B: Using CDK context
```bash
npm run deploy -- \
  -c googleClientId=your-google-client-id.apps.googleusercontent.com \
  -c googleClientSecret=your-google-client-secret
```

### 5. Note the Outputs

After deployment, CDK will output:
- User Pool ID
- App Client ID
- Identity Pool ID
- API Endpoint URL
- Cognito Domain
- **Google Redirect URI** - Add this to Google OAuth settings!

### 6. Update Google OAuth

1. Copy the `GoogleRedirectUri` from the output
2. Go to Google Cloud Console → APIs & Services → Credentials
3. Edit your OAuth 2.0 Client ID
4. Add the redirect URI to "Authorized redirect URIs"
5. Save

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

### Google OAuth Not Working
1. Verify Client ID and Secret are correct
2. Check that redirect URI is added to Google
3. Ensure it matches exactly (including https://)

## Next Steps

1. Update iOS app with configuration values:
   ```json
   {
     "userPoolId": "[from output]",
     "appClientId": "[from output]",
     "identityPoolId": "[from output]",
     "apiEndpoint": "[from output]",
     "cognitoDomain": "[from output]"
   }
   ```

2. Test authentication flow
3. Verify API endpoints work
4. Monitor CloudWatch logs