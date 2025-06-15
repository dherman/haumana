# AWS Cognito Setup Guide for Haumana

This guide walks through setting up AWS Cognito for Haumana with Google Sign-In federation.

## Prerequisites

- AWS account with appropriate permissions
- Google Cloud Console project with OAuth 2.0 client configured
- Google OAuth Client ID and Secret

## Step 1: Create Cognito User Pool

1. Navigate to AWS Cognito Console
2. Click "Create user pool"
3. Configure sign-in options:
   - **Authentication providers**: Select "Federated identity providers"
   - **Cognito user pool sign-in options**: Select "Email"
   
4. Configure security requirements:
   - **Password policy**: Choose "Cognito defaults"
   - **MFA**: Select "No MFA" (can be enabled later)
   
5. Configure sign-up experience:
   - **Self-registration**: Enable
   - **Required attributes**: email, name
   
6. Configure message delivery:
   - **Email provider**: Use Cognito default
   
7. Integrate your app:
   - **User pool name**: `haumana-users`
   - **App client name**: `haumana-ios`
   - **Client secret**: Don't generate (not needed for mobile apps)
   
8. Review and create

## Step 2: Configure Google Federation

1. In the User Pool, go to "Sign-in experience" tab
2. Under "Federated identity provider sign-in", click "Add identity provider"
3. Select "Google"
4. Enter Google app credentials:
   - **Client ID**: Your Google OAuth 2.0 client ID
   - **Client secret**: Your Google OAuth 2.0 client secret
   - **Authorize scope**: `profile email openid`
   
5. Map attributes:
   - `email` → Email
   - `name` → Name
   - `picture` → Picture
   
6. Save changes

## Step 3: Configure App Client

1. Go to "App integration" tab
2. Find your app client and click on it
3. Edit the hosted UI settings:
   - **Allowed callback URLs**: `haumana://signin`
   - **Allowed sign-out URLs**: `haumana://signout`
   - **OAuth 2.0 grant types**: Authorization code grant
   - **OpenID Connect scopes**: openid, email, profile
   
4. Save changes

## Step 4: Set up Cognito Domain

1. In "App integration" tab, find "Domain" section
2. Create a Cognito domain:
   - **Domain prefix**: `haumana` (or another unique name)
   - This creates: `haumana.auth.us-west-2.amazoncognito.com`
   
3. Save

## Step 5: Create Identity Pool

1. Go to AWS Cognito Identity Pools (Federated Identities)
2. Click "Create identity pool"
3. Configure:
   - **Identity pool name**: `haumana-identity`
   - **Authentication providers**: 
     - Cognito: Select your user pool and app client
     - Google: Add your Google Client ID
   
4. Configure permissions:
   - Create new IAM roles for authenticated and unauthenticated users
   - Authenticated role name: `Cognito_haumanaAuth_Role`
   - Unauthenticated role name: `Cognito_haumanaUnauth_Role`
   
5. Create pool

## Step 6: Configure IAM Roles

1. Go to IAM Console
2. Find `Cognito_haumanaAuth_Role`
3. Add inline policy for API access:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "execute-api:Invoke"
      ],
      "Resource": [
        "arn:aws:execute-api:us-west-2:*:*/prod/POST/pieces",
        "arn:aws:execute-api:us-west-2:*:*/prod/POST/sessions"
      ]
    }
  ]
}
```

## Step 7: Update Google OAuth Settings

1. Go to Google Cloud Console
2. Navigate to APIs & Services → Credentials
3. Edit your OAuth 2.0 Client ID
4. Add to Authorized redirect URIs:
   - `https://haumana.auth.us-west-2.amazoncognito.com/oauth2/idpresponse`

## Step 8: Record Configuration Values

Note these values for the iOS app configuration:

- **User Pool ID**: `us-west-2_XXXXXXXXX`
- **App Client ID**: `XXXXXXXXXXXXXXXXXXXXXXXXX`
- **Identity Pool ID**: `us-west-2:XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX`
- **Cognito Domain**: `haumana.auth.us-west-2.amazoncognito.com`

## Step 9: Update iOS App Configuration

1. Copy `amplifyconfiguration.template.json` to `amplifyconfiguration.json`
2. Replace placeholder values with your actual IDs
3. Add to `.gitignore` to keep credentials secure

## Testing

1. Test the hosted UI:
   ```
   https://haumana.auth.us-west-2.amazoncognito.com/login?client_id=YOUR_CLIENT_ID&response_type=code&scope=email+openid+profile&redirect_uri=haumana://signin
   ```

2. Verify Google Sign-In works
3. Check that tokens are issued correctly

## Troubleshooting

### Common Issues

1. **"redirect_uri_mismatch" error**: 
   - Ensure Google OAuth redirect URI matches Cognito domain
   - Format: `https://YOUR_DOMAIN.auth.REGION.amazoncognito.com/oauth2/idpresponse`

2. **"unauthorized_client" error**:
   - Verify Client ID and Secret are correct
   - Check that Google OAuth app is not in test mode

3. **User attributes not syncing**:
   - Review attribute mappings in Cognito
   - Ensure Google scopes include required attributes

## Security Best Practices

1. Enable MFA for production
2. Set up advanced security features (optional)
3. Configure password policies appropriately
4. Regularly rotate client secrets
5. Monitor sign-in metrics in CloudWatch

## Next Steps

1. Configure API Gateway with Cognito authorizer
2. Update iOS app with Amplify SDK
3. Implement token refresh logic
4. Add sign-out functionality