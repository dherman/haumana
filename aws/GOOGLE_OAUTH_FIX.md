# Google OAuth Configuration for AWS Cognito

## The Two-Client Solution

You need two separate OAuth clients in Google Cloud Console:

1. **iOS Client** (what you already have)
   - Type: iOS
   - No client secret
   - Used by: iOS app directly (future use)

2. **Web Client** (what Cognito needs)
   - Type: Web application
   - Has client secret
   - Used by: AWS Cognito

## Step-by-Step Fix

### 1. Create a Web Application OAuth Client

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **APIs & Services → Credentials**
3. Click **+ CREATE CREDENTIALS → OAuth client ID**
4. Choose **Web application** (not iOS!)
5. Configure:
   - Name: `Haumana Web (for Cognito)`
   - Authorized JavaScript origins: Leave empty for now
   - Authorized redirect URIs: Leave empty for now (we'll add after CDK deployment)
6. Click **CREATE**
7. **Save both the Client ID and Client Secret**

### 2. Understanding the Setup

```
User → Cognito Hosted UI → Google OAuth (using Web Client) → Back to Cognito → Your App

The flow:
1. User clicks "Sign in with Google" in Cognito's hosted UI
2. Cognito redirects to Google using the Web Client credentials
3. Google authenticates the user
4. Google redirects back to Cognito
5. Cognito creates tokens for your app
```

### 3. Use the Web Client for CDK

When deploying with CDK, use the **Web client** credentials:

```bash
export GOOGLE_CLIENT_ID="your-web-client-id.apps.googleusercontent.com"
export GOOGLE_CLIENT_SECRET="your-web-client-secret"
cdk deploy
```

### 4. After CDK Deployment

Update the Web client in Google Console:
1. Edit the Web application OAuth client
2. Add Authorized redirect URI from CDK output:
   ```
   https://haumana-xxxxx.auth.us-west-2.amazoncognito.com/oauth2/idpresponse
   ```

## Why This Works

- **Security**: The client secret is stored securely in AWS Cognito (server-side)
- **Mobile Safety**: Your iOS app never sees or needs the client secret
- **Proper Flow**: Cognito handles the OAuth dance with Google on behalf of your app

## Common Misconceptions

❌ **Wrong**: "I need to put the client secret in my iOS app"
✅ **Right**: The client secret stays in Cognito; your app only talks to Cognito

❌ **Wrong**: "I should use the iOS client ID with Cognito"
✅ **Right**: Cognito needs a Web application client with a secret

## Architecture Diagram

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│             │         │             │         │             │
│   iOS App   │────────▶│   Cognito   │────────▶│   Google    │
│             │         │  (Web Client)│         │    OAuth    │
└─────────────┘         └─────────────┘         └─────────────┘
     No secret            Has secret               Validates secret
```

## What About the iOS Client?

Keep your iOS OAuth client! In the future, if you want to use Google Sign-In SDK directly in the app (bypassing Cognito), you'll need it. For now, with Cognito handling authentication, you won't use it.

## Summary

1. Create a new **Web application** OAuth client in Google Console
2. Use its Client ID and Secret for CDK deployment
3. Your iOS app will authenticate through Cognito, not directly with Google
4. This is the secure, recommended approach for mobile apps using Cognito