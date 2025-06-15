# AWS Setup Checklist for Milestone 5

This checklist tracks the manual setup steps required for AWS infrastructure.

## Phase 1: AWS Setup (Days 1-2)

### Day 1: Cognito and DynamoDB Setup

#### DynamoDB Tables
- [ ] Run `aws/deploy.sh` to create tables automatically
- [ ] Verify tables created in AWS Console:
  - [ ] haumana-pieces table exists
  - [ ] haumana-sessions table exists
  - [ ] Global Secondary Indexes are configured

#### Cognito User Pool
- [ ] Create User Pool following `COGNITO_SETUP.md`:
  - [ ] User Pool Name: `haumana-users`
  - [ ] Sign-in with email enabled
  - [ ] Required attributes: email, name
  - [ ] App client created (no secret)
  
- [ ] Configure Google Federation:
  - [ ] Add Google as identity provider
  - [ ] Enter Google OAuth credentials
  - [ ] Map attributes (email, name, picture)
  
- [ ] Configure App Integration:
  - [ ] Callback URL: `haumana://signin`
  - [ ] Sign-out URL: `haumana://signout`
  - [ ] OAuth scopes: openid, email, profile
  
- [ ] Create Cognito Domain:
  - [ ] Domain prefix: ________________
  - [ ] Full domain: ________________.auth.us-west-2.amazoncognito.com

#### Cognito Identity Pool
- [ ] Create Identity Pool:
  - [ ] Name: `haumana-identity`
  - [ ] Link to User Pool
  - [ ] Add Google as authentication provider
  - [ ] Create IAM roles

#### Google OAuth Configuration
- [ ] Update Google Cloud Console:
  - [ ] Add Cognito redirect URI
  - [ ] Format: `https://[DOMAIN].auth.us-west-2.amazoncognito.com/oauth2/idpresponse`

### Day 2: API Setup

#### Lambda Functions
- [ ] Build Lambda functions:
  ```bash
  cd aws/lambdas
  npm run build:prod
  ```
- [ ] Deploy using `aws/deploy.sh`:
  - [ ] sync-pieces Lambda deployed
  - [ ] sync-sessions Lambda deployed
  - [ ] Environment variables configured

#### API Gateway
- [ ] Create REST API named `haumana-api`
- [ ] Create resources:
  - [ ] `/pieces` resource
  - [ ] `/sessions` resource
  
- [ ] Configure methods:
  - [ ] POST /pieces → sync-pieces Lambda
  - [ ] POST /sessions → sync-sessions Lambda
  
- [ ] Configure authorization:
  - [ ] Create Cognito User Pool authorizer
  - [ ] Apply to both endpoints
  
- [ ] Configure CORS:
  - [ ] Enable CORS on both endpoints
  - [ ] Allow Authorization header
  
- [ ] Deploy API:
  - [ ] Stage name: `prod`
  - [ ] Note API endpoint: ________________

#### IAM Roles and Policies
- [ ] Verify Lambda execution role has:
  - [ ] DynamoDB read/write access
  - [ ] CloudWatch logs access
  
- [ ] Update Cognito authenticated role:
  - [ ] Add API Gateway invoke permissions
  - [ ] Scope to specific API resources

## Configuration Values to Record

Fill in these values as you complete setup:

```json
{
  "region": "us-west-2",
  "userPoolId": "_________________",
  "appClientId": "_________________",
  "identityPoolId": "_________________",
  "cognitoDomain": "_________________",
  "apiEndpoint": "_________________",
  "googleClientId": "_________________"
}
```

## Verification Steps

### Test Cognito
- [ ] Access hosted UI at:
  ```
  https://[DOMAIN].auth.us-west-2.amazoncognito.com/login?client_id=[CLIENT_ID]&response_type=code&scope=email+openid+profile&redirect_uri=haumana://signin
  ```
- [ ] Verify Google Sign-In works
- [ ] Check JWT tokens are issued

### Test API
- [ ] Use Postman or curl to test endpoints
- [ ] Verify authorization is required
- [ ] Test with valid Cognito token

### Test Lambda Functions
- [ ] Check CloudWatch logs for both functions
- [ ] Verify DynamoDB access works
- [ ] Test error handling

## Troubleshooting

If you encounter issues:

1. **Cognito**: Check CloudWatch logs for Cognito events
2. **API Gateway**: Enable CloudWatch logging for debugging
3. **Lambda**: Check function logs in CloudWatch
4. **DynamoDB**: Verify table names and indexes

## Next Steps

Once all items are checked:
1. Copy configuration values to `amplifyconfiguration.json`
2. Proceed to Phase 2: Authentication Migration