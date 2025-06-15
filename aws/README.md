# Haumana AWS Infrastructure

This directory contains the AWS infrastructure components for Haumana's cloud sync functionality.

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Node.js 18+ and npm
3. An existing Google OAuth 2.0 client ID

## Quick Start

### 1. Create DynamoDB Tables

```bash
# Create the pieces table
aws dynamodb create-table --cli-input-json file://infrastructure/tables/pieces-table.json

# Create the sessions table  
aws dynamodb create-table --cli-input-json file://infrastructure/tables/sessions-table.json

# Verify tables were created
aws dynamodb list-tables
```

### 2. Set up Cognito (Manual Steps)

1. Go to AWS Cognito Console
2. Create a new User Pool named "haumana-users"
3. Configure Google as a federated identity provider
4. Create an Identity Pool linked to the User Pool
5. Note down the Pool IDs and Client ID

### 3. Build Lambda Functions

```bash
cd lambdas
npm install
npm run build:prod
```

### 4. Deploy Lambda Functions

```bash
# Create sync-pieces function
aws lambda create-function \
  --function-name haumana-sync-pieces \
  --runtime nodejs18.x \
  --handler dist/sync-pieces-lambda.handler \
  --zip-file fileb://dist/sync-pieces-lambda.js.zip \
  --role arn:aws:iam::YOUR_ACCOUNT:role/lambda-dynamodb-role \
  --environment Variables={PIECES_TABLE=haumana-pieces}

# Create sync-sessions function  
aws lambda create-function \
  --function-name haumana-sync-sessions \
  --runtime nodejs18.x \
  --handler dist/sync-sessions-lambda.handler \
  --zip-file fileb://dist/sync-sessions-lambda.js.zip \
  --role arn:aws:iam::YOUR_ACCOUNT:role/lambda-dynamodb-role \
  --environment Variables={SESSIONS_TABLE=haumana-sessions}
```

### 5. Set up API Gateway

1. Create a new REST API named "haumana-api"
2. Create resources:
   - `/pieces` with POST method → sync-pieces Lambda
   - `/sessions` with POST method → sync-sessions Lambda
3. Configure Cognito User Pool authorizer
4. Deploy to "prod" stage

## Development

### Running Lambda Functions Locally

```bash
# Install development dependencies
npm install --save-dev @types/aws-lambda

# Build TypeScript
npm run build

# Test locally (requires SAM CLI)
sam local start-api
```

### Updating Lambda Functions

```bash
# Build and bundle
npm run build:prod

# Update function code
aws lambda update-function-code \
  --function-name haumana-sync-pieces \
  --zip-file fileb://dist/sync-pieces-lambda.js.zip
```

## Architecture

- **DynamoDB Tables**:
  - `haumana-pieces`: Stores user repertoire with userId as partition key
  - `haumana-sessions`: Stores practice sessions with composite keys

- **Lambda Functions**:
  - `sync-pieces-lambda`: Handles piece synchronization (upload/download/sync)
  - `sync-sessions-lambda`: Handles practice session uploads

- **API Gateway**: REST API with Cognito authorization

## Environment Variables

- `PIECES_TABLE`: DynamoDB table name for pieces (default: haumana-pieces)
- `SESSIONS_TABLE`: DynamoDB table name for sessions (default: haumana-sessions)

## Cost Considerations

- DynamoDB: Pay-per-request billing mode
- Lambda: Pay per invocation and compute time
- API Gateway: Pay per API call
- Estimated monthly cost for 100 active users: ~$10-20

## Security

- All API endpoints require Cognito JWT authentication
- Lambda functions have minimal IAM permissions
- Data is encrypted at rest in DynamoDB
- HTTPS only for all API calls