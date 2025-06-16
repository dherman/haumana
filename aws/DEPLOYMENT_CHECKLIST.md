# AWS Infrastructure Deployment Checklist

Follow these steps to deploy your AWS infrastructure using CDK.

## Pre-Deployment Setup

### 1. Verify Prerequisites
- [x] AWS CLI is installed: `aws --version`
- [x] AWS CLI is configured: `aws sts get-caller-identity`
- [x] Node.js 18+ is installed: `node --version`
- [x] You have Google OAuth Client ID and Secret ready

### 2. Install AWS CDK
```bash
npm install -g aws-cdk
```
- [x] Verify: `cdk --version`

## Deployment Steps

### 3. Navigate to CDK Directory
```bash
cd aws/infrastructure/cdk
```
- [x] You're in the correct directory

### 4. Install Dependencies
```bash
npm install
```
- [x] Dependencies installed successfully

### 5. Bootstrap CDK (First Time Only)
```bash
cdk bootstrap
```
- [ ] Bootstrap completed (or already bootstrapped)

### 6. Build Lambda Functions
```bash
cd ../../lambdas
npm install
npm run build:prod
cd ../infrastructure/cdk
```
- [ ] Lambda functions built successfully

### 7. Store Google Client Secret in AWS Secrets Manager
```bash
# If creating new secret:
aws secretsmanager create-secret \
  --name haumana-oauth \
  --description "Google OAuth Client Secret" \
  --secret-string "your-actual-client-secret" \
  --region us-west-2

# If updating existing secret:
aws secretsmanager put-secret-value \
  --secret-id haumana-oauth \
  --secret-string "your-actual-client-secret" \
  --region us-west-2
```
- [ ] Client Secret stored in Secrets Manager

### 8. Set Google Client ID
```bash
export GOOGLE_CLIENT_ID="your-actual-client-id.apps.googleusercontent.com"
```
- [ ] Environment variable set

### 9. Deploy Stack
```bash
cdk deploy
```
- [ ] Review the changes CDK will make
- [ ] Type 'y' to confirm
- [ ] Wait for deployment (10-15 minutes)
- [ ] Deployment completed successfully

### 9. Save Output Values
Create `aws-config.json` (don't commit!):
```json
{
  "region": "us-west-2",
  "userPoolId": "[from output]",
  "appClientId": "[from output]",
  "identityPoolId": "[from output]",
  "cognitoDomain": "[from output]",
  "apiEndpoint": "[from output]",
  "googleClientId": "[your-google-client-id]"
}
```
- [ ] Configuration values saved

### 10. Update Google OAuth
1. Copy the `GoogleRedirectUri` from CDK output
2. Go to https://console.cloud.google.com/
3. APIs & Services → Credentials
4. Edit your OAuth 2.0 Client ID
5. Add the redirect URI
6. Save

- [ ] Google OAuth updated with Cognito redirect URI

## Verification

### 11. Test Cognito Hosted UI
Replace values and open in browser:
```
https://[your-cognito-domain].auth.us-west-2.amazoncognito.com/login?client_id=[YOUR_CLIENT_ID]&response_type=code&scope=email+openid+profile&redirect_uri=haumana://signin
```
- [ ] Login page loads
- [ ] Google sign-in button is visible
- [ ] Clicking Google goes to Google login

### 12. Check AWS Resources
Verify in AWS Console:
- [ ] Cognito User Pool exists (haumana-users)
- [ ] DynamoDB tables exist (haumana-pieces, haumana-sessions)
- [ ] Lambda functions deployed
- [ ] API Gateway has endpoints

## Post-Deployment

### 13. Update iOS App Configuration
Copy values to `ios/Haumana/Config/amplifyconfiguration.json`:
```json
{
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "CognitoUserPool": {
          "Default": {
            "PoolId": "[your-user-pool-id]",
            "AppClientId": "[your-app-client-id]",
            "Region": "us-west-2"
          }
        }
      }
    }
  },
  "api": {
    "plugins": {
      "awsAPIPlugin": {
        "haumanaAPI": {
          "endpoint": "[your-api-endpoint]",
          "region": "us-west-2",
          "authorizationType": "AMAZON_COGNITO_USER_POOLS"
        }
      }
    }
  }
}
```
- [ ] iOS configuration updated

## Troubleshooting

If something goes wrong:

### Deployment Fails
```bash
# Check CloudFormation stack
aws cloudformation describe-stack-events --stack-name HaumanaStack --region us-west-2

# Try again
cdk deploy --verbose
```

### Need to Start Over
```bash
# Delete everything (WARNING: deletes all data!)
cdk destroy

# Then deploy again
cdk deploy
```

### Google Sign-In Not Working
1. Wait 2-3 minutes for Google changes to propagate
2. Verify redirect URI is exactly: `https://[domain].auth.us-west-2.amazoncognito.com/oauth2/idpresponse`
3. Check that it includes `https://` and ends with `/oauth2/idpresponse`

## Success! 🎉

Once all boxes are checked, your AWS infrastructure is ready. You can now proceed to Phase 2: iOS App Integration.