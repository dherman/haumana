# Haumana AWS Infrastructure Quick Start with CDK

This guide will have your entire AWS infrastructure deployed in about 25 minutes.

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured (`aws configure`)
3. **Node.js 18+** and npm installed
4. **Google OAuth 2.0 Web Application credentials** (Client ID and Secret)
   - ⚠️ **Important**: You need a "Web application" client, not "iOS" or "Android"
   - If you only have an iOS client, see "Creating Google OAuth Credentials" below

## Step 1: Install AWS CDK (2 minutes)

```bash
npm install -g aws-cdk
```

Verify installation:
```bash
cdk --version
```

## Step 2: Prepare the Project (3 minutes)

```bash
# Navigate to CDK directory
cd aws/infrastructure/cdk

# Install dependencies
npm install

# Bootstrap CDK (first time only for your AWS account/region)
cdk bootstrap
```

## Step 3: Build Lambda Functions (2 minutes)

```bash
# Build the Lambda functions
cd ../../lambdas
npm install
npm run build:prod

# Return to CDK directory
cd ../infrastructure/cdk
```

## Step 4: Deploy Everything (15 minutes)

Set your Google credentials as environment variables:

```bash
export GOOGLE_CLIENT_ID="your-client-id.apps.googleusercontent.com"
export GOOGLE_CLIENT_SECRET="your-client-secret"
```

Deploy the stack:

```bash
npm run deploy
```

CDK will show you what it's going to create. Type `y` when prompted.

## Step 5: Save the Output (1 minute)

After deployment completes, you'll see output like:

```
Outputs:
HaumanaStack.ApiEndpoint = https://xxxxxxxxxx.execute-api.us-west-2.amazonaws.com/prod/
HaumanaStack.CognitoDomain = https://haumana-123456789012.auth.us-west-2.amazoncognito.com
HaumanaStack.GoogleRedirectUri = https://haumana-123456789012.auth.us-west-2.amazoncognito.com/oauth2/idpresponse
HaumanaStack.IdentityPoolId = us-west-2:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
HaumanaStack.UserPoolClientId = xxxxxxxxxxxxxxxxxxxxxxxxxx
HaumanaStack.UserPoolId = us-west-2_XXXXXXXXX
```

Save these values! Create a file `aws-config.json` (don't commit this):

```json
{
  "region": "us-west-2",
  "userPoolId": "us-west-2_XXXXXXXXX",
  "appClientId": "xxxxxxxxxxxxxxxxxxxxxxxxxx",
  "identityPoolId": "us-west-2:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "cognitoDomain": "haumana-123456789012",
  "apiEndpoint": "https://xxxxxxxxxx.execute-api.us-west-2.amazonaws.com/prod/",
  "googleClientId": "your-client-id.apps.googleusercontent.com"
}
```

## Step 6: Update Google OAuth (2 minutes)

1. Copy the `GoogleRedirectUri` from the CDK output
2. Go to [Google Cloud Console](https://console.cloud.google.com/)
3. Navigate to **APIs & Services → Credentials**
4. Click on your OAuth 2.0 Client ID
5. Under **Authorized redirect URIs**, click **ADD URI**
6. Paste the redirect URI from CDK output
7. Click **SAVE**

## Step 7: Test the Setup (5 minutes)

Test your Cognito hosted UI:

```bash
# Replace with your actual values
open "https://haumana-123456789012.auth.us-west-2.amazoncognito.com/login?client_id=YOUR_CLIENT_ID&response_type=code&scope=email+openid+profile&redirect_uri=haumana://signin"
```

You should see a login page with Google sign-in option.

## That's It! 🎉

Your entire AWS infrastructure is now deployed and configured. Total time: ~25 minutes.

## Next Steps

1. Update `ios/Haumana/Config/amplifyconfiguration.json` with your configuration values
2. Proceed to Phase 2: iOS App Integration

## Useful Commands

```bash
# View what will change before deploying
cdk diff

# Deploy updates
cdk deploy

# Delete everything (WARNING: this deletes all data!)
cdk destroy
```

## Troubleshooting

### "Stack already exists"
You might have already deployed. Try:
```bash
cdk diff  # See what would change
cdk deploy  # Update existing stack
```

### Google Sign-In Not Working
1. Make sure you saved the Google OAuth changes
2. Verify the redirect URI matches exactly (including https://)
3. Wait 1-2 minutes for Google changes to propagate

### Need to Change Something?
Edit `aws/infrastructure/cdk/lib/haumana-stack.ts` and run `cdk deploy` again.

---

## Creating Google OAuth Credentials

You need a **Web application** OAuth client for Cognito (even though this is a mobile app):

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable Google+ API:
   - Go to **APIs & Services → Library**
   - Search for "Google+ API"
   - Click Enable
4. Create credentials:
   - Go to **APIs & Services → Credentials**
   - Click **+ CREATE CREDENTIALS → OAuth client ID**
   - Application type: **Web application** (NOT iOS!)
   - Name: "Haumana Web (for Cognito)"
   - For now, don't add any redirect URIs (we'll add after CDK deployment)
   - Click **CREATE**
5. **Important**: Save both the Client ID and Client Secret

### Why Web Application?
- AWS Cognito acts as a backend service and needs a client secret
- Your iOS app will authenticate through Cognito, not directly with Google
- This is the secure, recommended approach for mobile apps using Cognito
- If you already have an iOS client, keep it (you might use it in the future)

## Environment-Specific Deployments

For multiple environments:

```bash
# Development
CDK_ENV=dev cdk deploy HaumanaStack-Dev

# Production  
CDK_ENV=prod cdk deploy HaumanaStack-Prod
```