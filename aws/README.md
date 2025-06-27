# Haumana AWS Infrastructure

AWS infrastructure components for Haumana's cloud sync functionality.

## 📚 Documentation

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Step-by-step deployment guide with CDK (~25 minutes)
- **[infrastructure/cdk/](infrastructure/cdk/README.md)** - CDK stack implementation details

### Additional Guides

- **[CloudWatch Alarms](infrastructure/docs/cloudwatch-alarms-setup.md)** - Monitoring setup
- **[AWS Budget](infrastructure/docs/create-haumana-budget.md)** - Cost tracking

## 🏗️ Architecture

### Components

- **DynamoDB Tables**:
  - `haumana-pieces`: Stores user repertoire (partition key: userId, sort key: pieceId)
  - `haumana-sessions`: Stores practice sessions with composite keys
  
- **Lambda Functions**:
  - `sync-pieces-lambda`: Handles piece synchronization (upload/download/sync)
  - `sync-sessions-lambda`: Handles practice session uploads
  - `auth-sync-lambda`: Syncs Google users to Cognito
  - `google-token-authorizer`: Validates Google ID tokens for API access

- **API Gateway**: REST API with custom Google token authorization
  - `POST /pieces` - Sync repertoire pieces
  - `POST /sessions` - Upload practice sessions
  - `POST /auth/sync` - Sync authentication

- **Authentication**:
  - Google Sign-In SDK → Google ID Token → Custom Authorizer → API Access
  - Cognito User Pool stores user data (not used for authentication)

### Data Flow

```
iOS App → Google Sign-In → ID Token
    ↓
API Gateway → Custom Authorizer (validates Google token)
    ↓
Lambda Functions → DynamoDB
```

## 🧪 Development

### Running Lambda Functions Locally

```bash
cd lambdas
npm install
npm run build
sam local start-api  # Requires AWS SAM CLI
```

### Updating Lambda Functions

After modifying Lambda code:
```bash
npm run build:prod
cdk deploy  # Redeploys all changes
```

## 💰 Cost Estimates

- **DynamoDB**: Pay-per-request (~$0.25 per million requests)
- **Lambda**: Free tier covers most usage
- **API Gateway**: $3.50 per million API calls
- **Total**: ~$10-20/month for 100 active users

## 🔒 Security

- **API Protection**: Custom authorizer validates Google ID tokens
- **Data Encryption**: At-rest encryption in DynamoDB
- **Network**: HTTPS only, no public database access
- **IAM**: Least-privilege permissions for all services