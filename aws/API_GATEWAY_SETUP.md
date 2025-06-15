# API Gateway Setup Guide for Haumana

This guide walks through setting up API Gateway for the Haumana sync API.

## Prerequisites

- Lambda functions deployed (sync-pieces, sync-sessions)
- Cognito User Pool created and configured
- AWS CLI configured

## Option 1: Import from Swagger (Recommended)

1. **Update the Swagger file**:
   - Edit `infrastructure/api-gateway-swagger.yaml`
   - Replace `YOUR_API_ID` with actual values
   - Replace `YOUR_ACCOUNT_ID` with your AWS account ID
   - Replace `YOUR_USER_POOL_ID` with your Cognito User Pool ID

2. **Import API**:
   ```bash
   aws apigateway import-rest-api \
     --body file://infrastructure/api-gateway-swagger.yaml \
     --region us-west-2
   ```

3. **Deploy API**:
   ```bash
   aws apigateway create-deployment \
     --rest-api-id YOUR_API_ID \
     --stage-name prod \
     --region us-west-2
   ```

## Option 2: Manual Setup via Console

### Step 1: Create API

1. Go to API Gateway Console
2. Click "Create API"
3. Choose "REST API" (not private)
4. Select "New API"
5. Settings:
   - API name: `haumana-api`
   - Description: `Haumana sync API`
   - Endpoint Type: Regional

### Step 2: Create Authorizer

1. In your API, go to "Authorizers"
2. Click "Create New Authorizer"
3. Configure:
   - Name: `CognitoUserPool`
   - Type: Cognito
   - Cognito User Pool: Select your pool
   - Token Source: `Authorization`
   - Token Validation: Leave empty

### Step 3: Create Resources and Methods

#### /pieces endpoint

1. Select root resource (/)
2. Actions → Create Resource
3. Configure:
   - Resource Name: `pieces`
   - Resource Path: `/pieces`
   - Enable CORS: ✓

4. Select /pieces resource
5. Actions → Create Method → POST
6. Configure:
   - Integration type: Lambda Function
   - Use Lambda Proxy integration: ✓
   - Lambda Region: us-west-2
   - Lambda Function: haumana-sync-pieces
   - Use Default Timeout: ✓

7. Method Request settings:
   - Authorization: CognitoUserPool
   - Request Validator: Validate body

#### /sessions endpoint

1. Repeat above steps for sessions:
   - Resource path: `/sessions`
   - Lambda function: haumana-sync-sessions
   - Same authorization and settings

### Step 4: Configure CORS

For each resource (/pieces and /sessions):

1. Select the resource
2. Actions → Enable CORS
3. Configure:
   - Access-Control-Allow-Origin: `*`
   - Access-Control-Allow-Headers: `Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token`
   - Access-Control-Allow-Methods: `GET,POST,OPTIONS`

### Step 5: Deploy API

1. Actions → Deploy API
2. Deployment stage: New Stage
3. Stage name: `prod`
4. Deploy

### Step 6: Grant Lambda Permissions

For each Lambda function, grant API Gateway permission to invoke:

```bash
# For sync-pieces
aws lambda add-permission \
  --function-name haumana-sync-pieces \
  --statement-id apigateway-invoke \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:us-west-2:YOUR_ACCOUNT_ID:YOUR_API_ID/*/*"

# For sync-sessions  
aws lambda add-permission \
  --function-name haumana-sync-sessions \
  --statement-id apigateway-invoke \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:us-west-2:YOUR_ACCOUNT_ID:YOUR_API_ID/*/*"
```

## Testing the API

### 1. Get Cognito Token

First, get an ID token from Cognito (you'll implement this in the app, but for testing):

```bash
# This is pseudo-code - actual implementation depends on your auth flow
aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id YOUR_CLIENT_ID \
  --auth-parameters USERNAME=user@example.com,PASSWORD=password
```

### 2. Test Pieces Endpoint

```bash
curl -X POST https://YOUR_API_ID.execute-api.us-west-2.amazonaws.com/prod/pieces \
  -H "Authorization: YOUR_ID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "operation": "download",
    "lastSyncedAt": "2024-01-01T00:00:00Z"
  }'
```

### 3. Test Sessions Endpoint

```bash
curl -X POST https://YOUR_API_ID.execute-api.us-west-2.amazonaws.com/prod/sessions \
  -H "Authorization: YOUR_ID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sessions": [{
      "sessionId": "test-123",
      "pieceId": "piece-456",
      "startedAt": "2024-01-01T10:00:00Z"
    }]
  }'
```

## Monitoring and Logs

### Enable CloudWatch Logs

1. Go to API Gateway Console
2. Select your API
3. Go to Settings
4. CloudWatch Settings:
   - CloudWatch Logs: Enable
   - Log level: INFO
   - Log full requests/responses: Yes (for debugging)

### View Logs

- API Gateway logs: CloudWatch → Log groups → `/aws/apigateway/haumana-api`
- Lambda logs: CloudWatch → Log groups → `/aws/lambda/haumana-sync-pieces`

## Troubleshooting

### Common Issues

1. **401 Unauthorized**
   - Check Cognito User Pool ID in authorizer
   - Verify token is valid and not expired
   - Ensure Authorization header is present

2. **500 Internal Server Error**
   - Check Lambda function logs
   - Verify Lambda has DynamoDB permissions
   - Check environment variables

3. **CORS errors**
   - Ensure OPTIONS method is configured
   - Check Access-Control headers
   - Verify client sends proper headers

4. **403 Forbidden**
   - Check Lambda invoke permissions
   - Verify API Gateway can call Lambda

## Production Considerations

1. **Throttling**:
   - Set up usage plans and API keys
   - Configure throttling limits

2. **Monitoring**:
   - Set up CloudWatch alarms
   - Monitor 4xx/5xx errors
   - Track latency metrics

3. **Security**:
   - Consider WAF for additional protection
   - Implement request validation
   - Use VPC endpoints if needed

## Next Steps

After API Gateway is configured:

1. Note the API endpoint URL
2. Update `amplifyconfiguration.json` with the endpoint
3. Test with Postman or curl
4. Proceed to iOS app integration