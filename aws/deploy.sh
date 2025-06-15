#!/bin/bash

# Deploy script for Haumana AWS infrastructure
# This script assumes AWS CLI is configured with appropriate credentials

set -e

echo "🚀 Starting Haumana AWS deployment..."

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=${AWS_REGION:-us-west-2}

echo "📋 Using AWS Account: $ACCOUNT_ID"
echo "📍 Region: $REGION"

# Step 1: Create DynamoDB tables
echo ""
echo "📊 Creating DynamoDB tables..."

# Check if pieces table exists
if aws dynamodb describe-table --table-name haumana-pieces &> /dev/null; then
    echo "✅ Table 'haumana-pieces' already exists"
else
    echo "Creating pieces table..."
    aws dynamodb create-table --cli-input-json file://infrastructure/tables/pieces-table.json
    echo "✅ Created table 'haumana-pieces'"
fi

# Check if sessions table exists
if aws dynamodb describe-table --table-name haumana-sessions &> /dev/null; then
    echo "✅ Table 'haumana-sessions' already exists"
else
    echo "Creating sessions table..."
    aws dynamodb create-table --cli-input-json file://infrastructure/tables/sessions-table.json
    echo "✅ Created table 'haumana-sessions'"
fi

# Step 2: Build Lambda functions
echo ""
echo "🔨 Building Lambda functions..."
cd lambdas
npm install
npm run build:prod
cd ..
echo "✅ Lambda functions built"

# Step 3: Create IAM role for Lambda (if not exists)
echo ""
echo "🔐 Setting up IAM role..."

ROLE_NAME="haumana-lambda-role"
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

if aws iam get-role --role-name $ROLE_NAME &> /dev/null; then
    echo "✅ IAM role '$ROLE_NAME' already exists"
else
    echo "Creating IAM role..."
    
    # Create trust policy
    cat > /tmp/trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

    # Create role
    aws iam create-role \
        --role-name $ROLE_NAME \
        --assume-role-policy-document file:///tmp/trust-policy.json
    
    # Attach policies
    aws iam attach-role-policy \
        --role-name $ROLE_NAME \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
    
    # Create and attach DynamoDB policy
    cat > /tmp/dynamodb-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:BatchWriteItem"
      ],
      "Resource": [
        "arn:aws:dynamodb:${REGION}:${ACCOUNT_ID}:table/haumana-pieces",
        "arn:aws:dynamodb:${REGION}:${ACCOUNT_ID}:table/haumana-pieces/index/*",
        "arn:aws:dynamodb:${REGION}:${ACCOUNT_ID}:table/haumana-sessions",
        "arn:aws:dynamodb:${REGION}:${ACCOUNT_ID}:table/haumana-sessions/index/*"
      ]
    }
  ]
}
EOF

    aws iam put-role-policy \
        --role-name $ROLE_NAME \
        --policy-name DynamoDBAccess \
        --policy-document file:///tmp/dynamodb-policy.json
    
    echo "✅ Created IAM role '$ROLE_NAME'"
    
    # Wait for role to be available
    echo "⏳ Waiting for IAM role to propagate..."
    sleep 10
fi

# Step 4: Package Lambda functions
echo ""
echo "📦 Packaging Lambda functions..."

cd lambdas/dist
zip -j sync-pieces-lambda.zip sync-pieces-lambda.js
zip -j sync-sessions-lambda.zip sync-sessions-lambda.js
cd ../..

# Step 5: Deploy Lambda functions
echo ""
echo "🚀 Deploying Lambda functions..."

# Deploy sync-pieces function
if aws lambda get-function --function-name haumana-sync-pieces &> /dev/null; then
    echo "Updating sync-pieces function..."
    aws lambda update-function-code \
        --function-name haumana-sync-pieces \
        --zip-file fileb://lambdas/dist/sync-pieces-lambda.zip
else
    echo "Creating sync-pieces function..."
    aws lambda create-function \
        --function-name haumana-sync-pieces \
        --runtime nodejs18.x \
        --handler sync-pieces-lambda.handler \
        --zip-file fileb://lambdas/dist/sync-pieces-lambda.zip \
        --role $ROLE_ARN \
        --environment Variables={PIECES_TABLE=haumana-pieces} \
        --timeout 30 \
        --memory-size 256
fi
echo "✅ Deployed sync-pieces function"

# Deploy sync-sessions function
if aws lambda get-function --function-name haumana-sync-sessions &> /dev/null; then
    echo "Updating sync-sessions function..."
    aws lambda update-function-code \
        --function-name haumana-sync-sessions \
        --zip-file fileb://lambdas/dist/sync-sessions-lambda.zip
else
    echo "Creating sync-sessions function..."
    aws lambda create-function \
        --function-name haumana-sync-sessions \
        --runtime nodejs18.x \
        --handler sync-sessions-lambda.handler \
        --zip-file fileb://lambdas/dist/sync-sessions-lambda.zip \
        --role $ROLE_ARN \
        --environment Variables={SESSIONS_TABLE=haumana-sessions} \
        --timeout 30 \
        --memory-size 256
fi
echo "✅ Deployed sync-sessions function"

# Cleanup
rm -f /tmp/trust-policy.json /tmp/dynamodb-policy.json

echo ""
echo "✅ AWS infrastructure deployment complete!"
echo ""
echo "Next steps:"
echo "1. Set up Cognito User Pool and Identity Pool"
echo "2. Configure API Gateway with Cognito authorizer"
echo "3. Update iOS app with Amplify configuration"
echo ""
echo "For detailed instructions, see aws/README.md"