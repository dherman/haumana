# Milestone 5: Cloud Sync and Data Backup - Implementation Plan

## Overview

This implementation plan details the technical steps to add cloud synchronization via AWS services to Haumana, enabling multi-device access and automatic data backup.

> **Update (June 2025)**: Due to issues with Cognito Hosted UI causing automatic re-authentication after sign-out, we are migrating to a hybrid authentication approach. See [Cognito Hybrid Authentication Migration Plan](./cognito-hybrid-auth-migration.md) for details.

## Prerequisites

1. AWS account with appropriate permissions
2. AWS CLI configured for deployment
3. Node.js and npm for Lambda development
4. Existing Google Sign-In authentication from Milestone 4

## Technical Architecture

### AWS Services
- **Authentication**: AWS Cognito (federated with Google)
- **API**: API Gateway + Lambda functions (TypeScript)
- **Database**: DynamoDB
- **SDK**: AWS Amplify for iOS client
- **Infrastructure**: AWS CDK or CloudFormation

### Data Flow
```
iOS App → Amplify SDK → API Gateway → Lambda → DynamoDB
                ↓
         Cognito Auth
```

## Phase 1: AWS Infrastructure Setup (Days 1-2)

### Day 1: Cognito and DynamoDB Setup

#### 1.1 Configure AWS Cognito
```bash
# Create Cognito User Pool
aws cognito-idp create-user-pool \
  --pool-name haumana-users \
  --schema Name=email,AttributeDataType=String,Required=true,Mutable=false

# Create Cognito Identity Pool
aws cognito-identity create-identity-pool \
  --identity-pool-name haumana-identity \
  --allow-unauthenticated-identities false \
  --supported-login-providers accounts.google.com=YOUR_GOOGLE_CLIENT_ID
```

#### 1.2 Create DynamoDB Tables

**Option A: Direct AWS CLI (Quick Start)**
```json
// infrastructure/tables/pieces-table.json
{
  "TableName": "haumana-pieces",
  "KeySchema": [
    { "AttributeName": "userId", "KeyType": "HASH" },
    { "AttributeName": "pieceId", "KeyType": "RANGE" }
  ],
  "AttributeDefinitions": [
    { "AttributeName": "userId", "AttributeType": "S" },
    { "AttributeName": "pieceId", "AttributeType": "S" },
    { "AttributeName": "modifiedAt", "AttributeType": "S" }
  ],
  "GlobalSecondaryIndexes": [{
    "IndexName": "userId-modifiedAt-index",
    "Keys": [
      { "AttributeName": "userId", "KeyType": "HASH" },
      { "AttributeName": "modifiedAt", "KeyType": "RANGE" }
    ],
    "Projection": { "ProjectionType": "ALL" },
    "ProvisionedThroughput": {
      "ReadCapacityUnits": 5,
      "WriteCapacityUnits": 5
    }
  }],
  "BillingMode": "PAY_PER_REQUEST"
}
```

```json
// infrastructure/tables/sessions-table.json
{
  "TableName": "haumana-sessions",
  "KeySchema": [
    { "AttributeName": "pk", "KeyType": "HASH" },
    { "AttributeName": "sk", "KeyType": "RANGE" }
  ],
  "AttributeDefinitions": [
    { "AttributeName": "pk", "AttributeType": "S" },
    { "AttributeName": "sk", "AttributeType": "S" },
    { "AttributeName": "pieceId", "AttributeType": "S" },
    { "AttributeName": "startedAt", "AttributeType": "S" }
  ],
  "GlobalSecondaryIndexes": [{
    "IndexName": "pieceId-startedAt-index",
    "Keys": [
      { "AttributeName": "pieceId", "KeyType": "HASH" },
      { "AttributeName": "startedAt", "KeyType": "RANGE" }
    ],
    "Projection": { "ProjectionType": "ALL" },
    "ProvisionedThroughput": {
      "ReadCapacityUnits": 5,
      "WriteCapacityUnits": 5
    }
  }],
  "BillingMode": "PAY_PER_REQUEST"
}
```

```bash
# Create tables using AWS CLI
aws dynamodb create-table --cli-input-json file://infrastructure/tables/pieces-table.json
aws dynamodb create-table --cli-input-json file://infrastructure/tables/sessions-table.json
```

**Option B: AWS CDK (Infrastructure as Code)**
```typescript
// infrastructure/dynamodb-tables.ts
import { Table, AttributeType, BillingMode } from '@aws-cdk/aws-dynamodb';
import { Construct } from 'constructs';

export class HaumanaTables extends Construct {
  public readonly piecesTable: Table;
  public readonly sessionsTable: Table;

  constructor(scope: Construct, id: string) {
    super(scope, id);

    // Pieces table
    this.piecesTable = new Table(this, 'PiecesTable', {
      tableName: 'haumana-pieces',
      partitionKey: { name: 'userId', type: AttributeType.STRING },
      sortKey: { name: 'pieceId', type: AttributeType.STRING },
      billingMode: BillingMode.PAY_PER_REQUEST,
    });

    // Add GSIs for different access patterns
    this.piecesTable.addGlobalSecondaryIndex({
      indexName: 'userId-modifiedAt-index',
      partitionKey: { name: 'userId', type: AttributeType.STRING },
      sortKey: { name: 'modifiedAt', type: AttributeType.STRING },
    });

    // Sessions table
    this.sessionsTable = new Table(this, 'SessionsTable', {
      tableName: 'haumana-sessions',
      partitionKey: { name: 'pk', type: AttributeType.STRING }, // USER#userId
      sortKey: { name: 'sk', type: AttributeType.STRING }, // SESSION#timestamp#sessionId
      billingMode: BillingMode.PAY_PER_REQUEST,
    });

    // GSI for piece-based queries
    this.sessionsTable.addGlobalSecondaryIndex({
      indexName: 'pieceId-startedAt-index',
      partitionKey: { name: 'pieceId', type: AttributeType.STRING },
      sortKey: { name: 'startedAt', type: AttributeType.STRING },
    });
  }
}
```

### Day 2: API Setup

#### 2.1 Lambda Functions Setup
```bash
# Create Lambda functions directory
mkdir -p aws/lambdas
cd aws/lambdas

# Initialize TypeScript project
npm init -y
npm install --save-dev typescript @types/node @types/aws-lambda esbuild
npm install @aws-sdk/client-dynamodb @aws-sdk/lib-dynamodb uuid

# Create tsconfig.json
cat > tsconfig.json << EOF
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  }
}
EOF
```

#### 2.2 Create Lambda Functions

#### auth-sync-lambda.ts (Hybrid Authentication)
```typescript
import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { CognitoIdentityProviderClient, AdminCreateUserCommand, AdminUpdateUserAttributesCommand, ListUsersCommand } from '@aws-sdk/client-cognito-identity-provider';
import { OAuth2Client } from 'google-auth-library';

const cognitoClient = new CognitoIdentityProviderClient({ region: process.env.AWS_REGION });
const googleClient = new OAuth2Client();
const USER_POOL_ID = process.env.USER_POOL_ID || '';

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    const body = JSON.parse(event.body || '{}');
    const { googleIdToken } = body;
    
    if (!googleIdToken) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Missing googleIdToken' })
      };
    }
    
    // Verify Google token
    const ticket = await googleClient.verifyIdToken({
      idToken: googleIdToken,
      audience: [
        process.env.GOOGLE_CLIENT_ID || '', // Web client ID
        '872799888201-rdv0c48nup16mo4b19jjred0jgpjoltc.apps.googleusercontent.com' // iOS client ID
      ]
    });
    
    const payload = ticket.getPayload();
    if (!payload) {
      throw new Error('Invalid token payload');
    }
    
    const { sub: googleUserId, email, name, picture } = payload;
    
    // Check if user exists in Cognito
    const listUsersResponse = await cognitoClient.send(new ListUsersCommand({
      UserPoolId: USER_POOL_ID,
      Filter: `email = "${email}"`
    }));
    
    let cognitoUser;
    if (listUsersResponse.Users && listUsersResponse.Users.length > 0) {
      // Update existing user
      cognitoUser = listUsersResponse.Users[0];
      await cognitoClient.send(new AdminUpdateUserAttributesCommand({
        UserPoolId: USER_POOL_ID,
        Username: cognitoUser.Username!,
        UserAttributes: [
          { Name: 'name', Value: name || '' },
          { Name: 'picture', Value: picture || '' },
          { Name: 'updated_at', Value: Math.floor(Date.now() / 1000).toString() }
        ]
      }));
    } else {
      // Create new user
      const createUserResponse = await cognitoClient.send(new AdminCreateUserCommand({
        UserPoolId: USER_POOL_ID,
        Username: googleUserId,
        UserAttributes: [
          { Name: 'email', Value: email || '' },
          { Name: 'name', Value: name || '' },
          { Name: 'picture', Value: picture || '' }
        ],
        MessageAction: 'SUPPRESS'
      }));
      cognitoUser = createUserResponse.User;
    }
    
    return {
      statusCode: 200,
      body: JSON.stringify({
        success: true,
        user: {
          id: cognitoUser?.Username,
          email,
          name,
          picture
        }
      })
    };
  } catch (error) {
    console.error('Lambda error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ 
        error: 'Internal server error',
        message: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};
```

#### sync-pieces-lambda.ts
```typescript
import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand, QueryCommand, BatchWriteCommand } from '@aws-sdk/lib-dynamodb';
import { v4 as uuidv4 } from 'uuid';

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);
const PIECES_TABLE = process.env.PIECES_TABLE || 'haumana-pieces';

interface Piece {
  pieceId: string;
  userId: string;
  title: string;
  category: 'oli' | 'mele';
  lyrics: string;
  language?: string;
  englishTranslation?: string;
  author?: string;
  sourceUrl?: string;
  notes?: string;
  includeInPractice: boolean;
  isFavorite: boolean;
  createdAt: string;
  modifiedAt: string;
  lastSyncedAt: string;
  version: number;
  locallyModified?: boolean;
}

interface SyncRequest {
  operation: 'sync' | 'upload' | 'download';
  pieces?: Piece[];
  lastSyncedAt?: string;
}

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    const body: SyncRequest = JSON.parse(event.body || '{}');
    const userId = event.requestContext.authorizer?.claims?.sub;
    
    if (!userId) {
      return {
        statusCode: 401,
        body: JSON.stringify({ error: 'Unauthorized' })
      };
    }
    
    const operation = body.operation || 'sync';
    
    switch (operation) {
      case 'upload':
        return await handleUpload(userId, body.pieces || []);
      case 'download':
        return await handleDownload(userId, body.lastSyncedAt);
      case 'sync':
        return await handleSync(userId, body.pieces || [], body.lastSyncedAt);
      default:
        return {
          statusCode: 400,
          body: JSON.stringify({ error: 'Invalid operation' })
        };
    }
  } catch (error) {
    console.error('Lambda error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error instanceof Error ? error.message : 'Internal server error' })
    };
  }
};

async function handleUpload(userId: string, pieces: Piece[]): Promise<APIGatewayProxyResult> {
  const uploadedPieces: string[] = [];
  const batchSize = 25; // DynamoDB batch write limit
  const now = new Date().toISOString();
  
  // Process in batches of 25
  for (let i = 0; i < pieces.length; i += batchSize) {
    const batch = pieces.slice(i, i + batchSize);
    const putRequests = batch.map(piece => {
      // Ensure userId matches authenticated user
      piece.userId = userId;
      piece.lastSyncedAt = now;
      
      // Generate pieceId if not present
      if (!piece.pieceId) {
        piece.pieceId = uuidv4();
      }
      
      // Update version for optimistic locking
      piece.version = (piece.version || 0) + 1;
      
      uploadedPieces.push(piece.pieceId);
      
      return {
        PutRequest: {
          Item: piece
        }
      };
    });
    
    await docClient.send(new BatchWriteCommand({
      RequestItems: {
        [PIECES_TABLE]: putRequests
      }
    }));
  }
  
  return {
    statusCode: 200,
    body: JSON.stringify({
      uploadedPieces,
      syncedAt: now
    })
  };
}

async function handleDownload(userId: string, lastSyncedAt?: string): Promise<APIGatewayProxyResult> {
  const queryParams: any = {
    TableName: PIECES_TABLE,
    KeyConditionExpression: 'userId = :userId',
    ExpressionAttributeValues: {
      ':userId': userId
    }
  };
  
  if (lastSyncedAt) {
    queryParams.FilterExpression = 'lastSyncedAt > :lastSync';
    queryParams.ExpressionAttributeValues[':lastSync'] = lastSyncedAt;
  }
  
  const response = await docClient.send(new QueryCommand(queryParams));
  
  return {
    statusCode: 200,
    body: JSON.stringify({
      pieces: response.Items || [],
      syncedAt: new Date().toISOString()
    })
  };
}

async function handleSync(
  userId: string, 
  clientPieces: Piece[], 
  lastSyncedAt?: string
): Promise<APIGatewayProxyResult> {
  // Get server pieces modified since last sync
  const serverResponse = await handleDownload(userId, lastSyncedAt);
  const serverData = JSON.parse(serverResponse.body);
  const serverPieces = serverData.pieces;
  
  // Upload client changes
  const changesToUpload = clientPieces.filter(piece => piece.locallyModified);
  let uploadedCount = 0;
  
  if (changesToUpload.length > 0) {
    const uploadResponse = await handleUpload(userId, changesToUpload);
    const uploadData = JSON.parse(uploadResponse.body);
    uploadedCount = uploadData.uploadedPieces.length;
  }
  
  return {
    statusCode: 200,
    body: JSON.stringify({
      serverPieces,
      uploadedCount,
      syncedAt: new Date().toISOString()
    })
  };
}
```

#### sync-sessions-lambda.ts
```typescript
import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, BatchWriteCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);
const SESSIONS_TABLE = process.env.SESSIONS_TABLE || 'haumana-sessions';

interface PracticeSession {
  sessionId: string;
  userId: string;
  pieceId: string;
  startedAt: string;
  endedAt?: string;
  endedAtSource?: 'manual' | 'automatic' | 'estimated';
  createdAt: string;
}

interface SyncSessionsRequest {
  sessions: PracticeSession[];
}

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    const body: SyncSessionsRequest = JSON.parse(event.body || '{}');
    const userId = event.requestContext.authorizer?.claims?.sub;
    
    if (!userId) {
      return {
        statusCode: 401,
        body: JSON.stringify({ error: 'Unauthorized' })
      };
    }
    
    const sessions = body.sessions || [];
    const uploadedSessions: string[] = [];
    const batchSize = 25; // DynamoDB batch write limit
    const now = new Date().toISOString();
    
    // Process in batches of 25
    for (let i = 0; i < sessions.length; i += batchSize) {
      const batch = sessions.slice(i, i + batchSize);
      const putRequests = batch.map(session => {
        // Ensure userId matches authenticated user
        session.userId = userId;
        
        // Create composite sort key for efficient querying
        const sk = `SESSION#${session.startedAt}#${session.sessionId}`;
        
        uploadedSessions.push(session.sessionId);
        
        return {
          PutRequest: {
            Item: {
              ...session,
              pk: `USER#${userId}`,
              sk,
              syncedAt: now
            }
          }
        };
      });
      
      await docClient.send(new BatchWriteCommand({
        RequestItems: {
          [SESSIONS_TABLE]: putRequests
        }
      }));
    }
    
    return {
      statusCode: 200,
      body: JSON.stringify({
        uploadedSessions,
        syncedAt: now
      })
    };
    
  } catch (error) {
    console.error('Lambda error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error instanceof Error ? error.message : 'Internal server error' })
    };
  }
};
```

#### 2.3 API Gateway Configuration
```typescript
// infrastructure/api-gateway.ts
import { RestApi, LambdaIntegration, CognitoUserPoolsAuthorizer } from '@aws-cdk/aws-apigateway';
import { Function } from '@aws-cdk/aws-lambda';
import { UserPool } from '@aws-cdk/aws-cognito';
import { Construct } from 'constructs';

export class HaumanaApi extends Construct {
  constructor(
    scope: Construct, 
    id: string, 
    userPool: UserPool,
    syncPiecesLambda: Function,
    syncSessionsLambda: Function
  ) {
    super(scope, id);

    const api = new RestApi(this, 'HaumanaApi', {
      restApiName: 'Haumana API',
      deployOptions: {
        stageName: 'prod',
      },
    });

    const authorizer = new CognitoUserPoolsAuthorizer(this, 'ApiAuthorizer', {
      cognitoUserPools: [userPool],
    });

    // Pieces endpoint
    const pieces = api.root.addResource('pieces');
    pieces.addMethod('POST', new LambdaIntegration(syncPiecesLambda), {
      authorizer,
      authorizationType: AuthorizationType.COGNITO_USER_POOLS,
    });

    // Sessions endpoint
    const sessions = api.root.addResource('sessions');
    sessions.addMethod('POST', new LambdaIntegration(syncSessionsLambda), {
      authorizer,
      authorizationType: AuthorizationType.COGNITO_USER_POOLS,
    });
  }
}
```

## Phase 2: Authentication Migration (Days 3-4)

### Day 3: Integrate AWS Amplify

#### 3.1 Add Amplify SDK
```swift
// Package.swift or Xcode Package Manager
dependencies: [
    .package(url: "https://github.com/aws-amplify/amplify-swift", from: "2.0.0")
]
```

#### 3.2 Configure Amplify
```swift
// Config/amplifyconfiguration.json
{
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "IdentityManager": {
          "Default": {}
        },
        "CredentialsProvider": {
          "CognitoIdentity": {
            "Default": {
              "PoolId": "YOUR_IDENTITY_POOL_ID",
              "Region": "us-west-2"
            }
          }
        },
        "CognitoUserPool": {
          "Default": {
            "PoolId": "YOUR_USER_POOL_ID",
            "AppClientId": "YOUR_APP_CLIENT_ID",
            "Region": "us-west-2"
          }
        },
        // Note: No Auth configuration needed
        // We use Google Sign-In SDK directly, not Cognito Hosted UI
      }
    }
  },
  "api": {
    "plugins": {
      "awsAPIPlugin": {
        "haumanaAPI": {
          "endpointType": "REST",
          "endpoint": "https://YOUR_API_ID.execute-api.us-west-2.amazonaws.com/prod",
          "region": "us-west-2",
          "authorizationType": "AMAZON_COGNITO_USER_POOLS"
        }
      }
    }
  }
}
```

#### 3.3 Update Authentication Service
```swift
// Services/AuthenticationService.swift
import Amplify
import AWSCognitoAuthPlugin
import AWSAPIPlugin

@MainActor
class AuthenticationService: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: AuthenticationError?
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        configureAmplify()
        checkAuthStatus()
    }
    
    private func configureAmplify() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.configure()
        } catch {
            print("Failed to configure Amplify: \(error)")
        }
    }
    
    func signInWithGoogle() async throws {
        let result = try await Amplify.Auth.signInWithWebUI(
            for: .google,
            presentationAnchor: self.window
        )
        
        if case .done = result.nextStep {
            let user = try await Amplify.Auth.getCurrentUser()
            await createOrUpdateUser(cognitoUser: user)
        }
    }
    
    private func createOrUpdateUser(cognitoUser: AuthUser) async {
        let attributes = try? await Amplify.Auth.fetchUserAttributes()
        
        let email = attributes?.first(where: { $0.key == .email })?.value ?? ""
        let name = attributes?.first(where: { $0.key == .name })?.value ?? ""
        
        let user = User(
            id: cognitoUser.userId,
            email: email,
            displayName: name
        )
        
        modelContext.insert(user)
        try? modelContext.save()
        self.user = user
        self.isAuthenticated = true
    }
}
```

### Day 4: Complete Auth Migration

#### 4.1 Update Sign-In View
```swift
// Views/SignInView.swift
struct SignInView: View {
    @StateObject private var authService = AuthenticationService.shared
    
    var body: some View {
        ZStack {
            Color.lehua
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Image("lehua")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                
                Text("Haumana")
                    .font(.custom("Adelia", size: 48))
                    .foregroundColor(.white)
                
                Button(action: {
                    Task {
                        do {
                            try await authService.signInWithGoogle()
                        } catch {
                            print("Sign in error: \(error)")
                        }
                    }
                }) {
                    HStack {
                        Image("google_logo")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text("Sign in with Google")
                            .font(.system(size: 17, weight: .medium))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(8)
                }
                .disabled(authService.isLoading)
            }
            
            if authService.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
    }
}
```

## Phase 3: Sync Service Implementation (Days 5-7)

### Day 5: Core Sync Service

#### 5.1 Create Sync Service
```swift
// Services/SyncService.swift
import Foundation
import Amplify
import SwiftData

@MainActor
class SyncService: ObservableObject {
    @Published var syncStatus: SyncStatus = .synced
    @Published var lastSyncedAt: Date?
    @Published var pendingChanges = 0
    
    private let modelContext: ModelContext
    private var syncTimer: Timer?
    private let syncQueue = DispatchQueue(label: "com.haumana.sync", qos: .background)
    
    enum SyncStatus {
        case synced
        case syncing
        case pendingChanges
        case offline
        case error(String)
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupReachability()
        startPeriodicSync()
    }
    
    func syncNow() async {
        guard syncStatus != .syncing else { return }
        
        syncStatus = .syncing
        
        do {
            // Sync pieces
            try await syncPieces()
            
            // Sync sessions
            try await syncSessions()
            
            lastSyncedAt = Date()
            syncStatus = .synced
            pendingChanges = 0
        } catch {
            syncStatus = .error(error.localizedDescription)
        }
    }
    
    private func syncPieces() async throws {
        let repository = PieceRepository(modelContext: modelContext)
        let localPieces = try repository.fetchAll()
        
        // Prepare request
        let request = RESTRequest(
            path: "/pieces",
            body: try JSONEncoder().encode([
                "operation": "sync",
                "pieces": localPieces.filter { $0.locallyModified },
                "lastSyncedAt": lastSyncedAt?.ISO8601Format()
            ])
        )
        
        // Make API call
        let data = try await Amplify.API.post(request: request)
        let response = try JSONDecoder().decode(SyncResponse.self, from: data)
        
        // Process server changes
        for serverPiece in response.serverPieces {
            try await repository.createOrUpdate(serverPiece)
        }
    }
    
    private func syncSessions() async throws {
        let repository = PracticeSessionRepository(modelContext: modelContext)
        let pendingSessions = try repository.fetchUnsyncedSessions()
        
        guard !pendingSessions.isEmpty else { return }
        
        let request = RESTRequest(
            path: "/sessions",
            body: try JSONEncoder().encode([
                "sessions": pendingSessions
            ])
        )
        
        let data = try await Amplify.API.post(request: request)
        let response = try JSONDecoder().decode(SessionSyncResponse.self, from: data)
        
        // Mark sessions as synced
        for sessionId in response.uploadedSessions {
            try repository.markAsSynced(sessionId: sessionId)
        }
    }
}
```

### Day 6: Offline Queue Management

#### 6.1 Offline Queue
```swift
// Services/OfflineQueue.swift
import Foundation
import SwiftData

@Model
final class SyncQueueItem {
    var id: UUID
    var entityType: String // "piece" or "session"
    var entityId: String
    var operation: String // "create", "update", "delete"
    var timestamp: Date
    var retryCount: Int
    var lastError: String?
    
    init(entityType: String, entityId: String, operation: String) {
        self.id = UUID()
        self.entityType = entityType
        self.entityId = entityId
        self.operation = operation
        self.timestamp = Date()
        self.retryCount = 0
    }
}

class OfflineQueueManager {
    private let modelContext: ModelContext
    private let maxRetries = 3
    
    func enqueue(entityType: String, entityId: String, operation: String) {
        let item = SyncQueueItem(
            entityType: entityType,
            entityId: entityId,
            operation: operation
        )
        modelContext.insert(item)
        try? modelContext.save()
    }
    
    func processQueue() async throws {
        let descriptor = FetchDescriptor<SyncQueueItem>(
            predicate: #Predicate { $0.retryCount < maxRetries },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        
        let items = try modelContext.fetch(descriptor)
        
        for item in items {
            do {
                try await processItem(item)
                modelContext.delete(item)
            } catch {
                item.retryCount += 1
                item.lastError = error.localizedDescription
            }
        }
        
        try modelContext.save()
    }
    
    private func processItem(_ item: SyncQueueItem) async throws {
        switch item.entityType {
        case "piece":
            try await syncPiece(id: item.entityId, operation: item.operation)
        case "session":
            try await syncSession(id: item.entityId, operation: item.operation)
        default:
            throw SyncError.unknownEntityType
        }
    }
}
```

### Day 7: Conflict Resolution

#### 7.1 Conflict Resolution Strategy
```swift
// Services/ConflictResolver.swift
import Foundation

struct ConflictResolver {
    enum Resolution {
        case keepLocal
        case keepRemote
        case merge(Piece)
    }
    
    static func resolve(local: Piece, remote: Piece) -> Resolution {
        // Last-write-wins based on modifiedAt
        if local.modifiedAt > remote.modifiedAt {
            return .keepLocal
        } else if remote.modifiedAt > local.modifiedAt {
            return .keepRemote
        } else {
            // Same timestamp - prefer remote (server as source of truth)
            return .keepRemote
        }
    }
    
    // Future: Three-way merge for lyrics
    static func mergeConflict(local: Piece, remote: Piece, base: Piece?) -> Piece {
        // For now, use last-write-wins
        return local.modifiedAt > remote.modifiedAt ? local : remote
    }
}
```

## Phase 4: UI Integration (Days 8-9)

### Day 8: Sync Status UI

#### 8.1 Sync Status View
```swift
// Views/SyncStatusView.swift
struct SyncStatusView: View {
    @ObservedObject var syncService: SyncService
    
    var body: some View {
        HStack(spacing: 8) {
            statusIcon
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch syncService.syncStatus {
        case .synced:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .syncing:
            ProgressView()
                .scaleEffect(0.8)
        case .pendingChanges:
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundColor(.orange)
        case .offline:
            Image(systemName: "wifi.slash")
                .foregroundColor(.gray)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
        }
    }
    
    private var statusText: String {
        switch syncService.syncStatus {
        case .synced:
            if let lastSync = syncService.lastSyncedAt {
                return "Synced \(lastSync.formatted(.relative(presentation: .named)))"
            }
            return "Synced"
        case .syncing:
            return "Syncing..."
        case .pendingChanges:
            return "\(syncService.pendingChanges) pending"
        case .offline:
            return "Offline"
        case .error(let message):
            return "Sync error"
        }
    }
}
```

#### 8.2 Update Navigation Bars
```swift
// Views/RepertoireListView.swift
struct RepertoireListView: View {
    @StateObject private var syncService = SyncService.shared
    
    var body: some View {
        NavigationStack {
            // ... existing content ...
            .navigationTitle("Repertoire")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SyncStatusView(syncService: syncService)
                }
            }
            .refreshable {
                await syncService.syncNow()
            }
        }
    }
}
```

### Day 9: Profile Tab Updates

#### 9.1 Sync Settings Section
```swift
// Views/ProfileTabView.swift
struct ProfileTabView: View {
    @StateObject private var syncService = SyncService.shared
    
    var body: some View {
        NavigationStack {
            List {
                // ... existing sections ...
                
                Section("Sync Status") {
                    HStack {
                        Text("Status")
                        Spacer()
                        SyncStatusView(syncService: syncService)
                    }
                    
                    if let lastSync = syncService.lastSyncedAt {
                        HStack {
                            Text("Last synced")
                            Spacer()
                            Text(lastSync.formatted(date: .abbreviated, time: .shortened))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if syncService.pendingChanges > 0 {
                        HStack {
                            Text("Pending changes")
                            Spacer()
                            Text("\(syncService.pendingChanges)")
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Button(action: {
                        Task {
                            await syncService.syncNow()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Sync Now")
                        }
                    }
                    .disabled(syncService.syncStatus == .syncing)
                }
                
                Section("Data & Storage") {
                    Button(action: clearLocalCache) {
                        Text("Clear Local Cache")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
}
```

## Phase 5: Practice Session Sync (Day 10)

### Day 10: Session Repository Updates

#### 10.1 Update Practice Session Repository
```swift
// Repositories/PracticeSessionRepository.swift
extension PracticeSessionRepository {
    func fetchUnsyncedSessions() throws -> [PracticeSession] {
        let descriptor = FetchDescriptor<PracticeSession>(
            predicate: #Predicate { session in
                session.syncedAt == nil
            },
            sortBy: [SortDescriptor(\.startedAt)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    func markAsSynced(sessionId: String) throws {
        let descriptor = FetchDescriptor<PracticeSession>(
            predicate: #Predicate { $0.id == sessionId }
        )
        
        if let session = try modelContext.fetch(descriptor).first {
            session.syncedAt = Date()
            try modelContext.save()
        }
    }
    
    func create(_ session: PracticeSession) throws {
        session.userId = AuthenticationService.shared.currentUser?.id
        modelContext.insert(session)
        try modelContext.save()
        
        // Queue for sync
        Task {
            await SyncService.shared.queueSessionSync(session.id)
        }
    }
}
```

## Phase 6: Testing and Polish (Days 11-14)

### Day 11-12: Comprehensive Testing

#### 11.1 Unit Tests
```swift
// Tests/SyncServiceTests.swift
class SyncServiceTests: XCTestCase {
    func testPieceSync() async throws
    func testSessionSync() async throws
    func testConflictResolution() async throws
    func testOfflineQueue() async throws
    func testRetryLogic() async throws
}

// Tests/AuthenticationTests.swift
class CognitoAuthTests: XCTestCase {
    func testGoogleSignIn() async throws
    func testTokenRefresh() async throws
    func testSignOut() async throws
}
```

#### 11.2 Integration Tests
```swift
// Tests/IntegrationTests.swift
class SyncIntegrationTests: XCTestCase {
    func testFullSyncCycle() async throws
    func testMultiDeviceSync() async throws
    func testOfflineToOnlineTransition() async throws
    func testLargeDatasetSync() async throws
}
```

### Day 13: Performance Optimization

#### 13.1 Batch Operations
```swift
// Optimize sync for large repertoires
extension SyncService {
    private func batchSync(pieces: [Piece], batchSize: Int = 25) async throws {
        for batch in pieces.chunked(into: batchSize) {
            try await syncBatch(batch)
            
            // Update progress
            let progress = Float(batch.count) / Float(pieces.count)
            await MainActor.run {
                self.syncProgress = progress
            }
        }
    }
}
```

### Day 14: Final Polish

#### 14.1 Error Handling
```swift
// Services/SyncErrorHandler.swift
struct SyncErrorHandler {
    static func handle(_ error: Error) -> UserFacingError {
        switch error {
        case let apiError as APIError:
            return handleAPIError(apiError)
        case let authError as AuthError:
            return handleAuthError(authError)
        default:
            return .generic("Sync failed. Please try again.")
        }
    }
}
```

## Testing Checklist

### Manual Testing Scenarios
- [ ] Sign in on device A, add pieces, sign in on device B, verify pieces appear
- [ ] Make changes on both devices while offline, go online, verify conflict resolution
- [ ] Create practice sessions offline, verify they sync when online
- [ ] Test with slow/intermittent connectivity
- [ ] Test with 1000+ pieces
- [ ] Force quit app during sync, verify recovery
- [ ] Sign out and sign in with different account, verify data isolation

### Automated Test Coverage
- [ ] Unit tests: 80%+ coverage
- [ ] Integration tests: Critical paths covered
- [ ] UI tests: Authentication and sync flows
- [ ] Performance tests: Large dataset handling

## Deployment Checklist

### AWS Resources
- [ ] Cognito User Pool configured
- [ ] Cognito Identity Pool configured
- [ ] DynamoDB tables created with proper indexes
- [ ] Lambda functions deployed
- [ ] API Gateway configured with authorizers
- [ ] IAM roles and policies set up
- [ ] CloudWatch alarms configured
- [ ] Cost monitoring enabled

### iOS App
- [ ] Amplify configuration file added
- [ ] Info.plist updated with URL schemes
- [ ] App Transport Security configured
- [ ] Privacy policy updated
- [ ] Terms of service updated

## Success Metrics

### Technical Metrics
- Sync success rate > 99%
- Average sync time < 3 seconds for typical repertoire
- Zero data loss incidents
- API response time < 500ms p95

### User Metrics
- Multi-device adoption rate
- Sync-related support tickets < 1%
- User satisfaction score > 4.5/5

## Risk Mitigation

### Identified Risks
1. **AWS Cost Overrun**
   - Mitigation: Set up billing alerts, use on-demand DynamoDB
   
2. **Sync Conflicts**
   - Mitigation: Start with simple last-write-wins, clear UI feedback
   
3. **Performance with Large Repertoires**
   - Mitigation: Implement pagination, progressive sync
   
4. **Authentication Migration Issues**
   - Mitigation: Thorough testing, gradual rollout

## Phase 7: Fix Authentication and Configuration (Days 15-16)

### Day 15: Fix API Gateway Authorization

#### 15.1 Implement Custom Authorizer (Option 1 from sync-authentication-todo.md)
- Create Lambda authorizer function to validate Google ID tokens
- Update API Gateway to use custom authorizer instead of Cognito User Pools
- Extract user ID from Google token and pass to backend Lambda functions
- Remove dependency on Cognito JWT tokens for API calls

#### 15.2 Update iOS SyncService
- Modify SyncService to include Google ID token in Authorization header
- Update makeAuthenticatedRequest method to use Google tokens
- Test API calls with new authorization mechanism
- Ensure proper error handling for auth failures

### Day 16: Create Amplify Configuration

#### 16.1 Create amplifyconfiguration.json
- Generate proper configuration file from template
- Include correct Cognito pool IDs and API endpoint
- Configure auth and API plugins properly
- Ensure configuration matches AWS resources

#### 16.2 Test End-to-End Sync
- Verify authentication flow works with new authorizer
- Test piece sync (upload and download)
- Test practice session sync
- Ensure sync status updates correctly in UI

## Phase 8: Fix Sync Issues (Days 17-18)

### Day 17: Fix Sync Filter and Bidirectional Sync

#### 17.1 Fix LocallyModified Filter Issue
- Remove the filter that only syncs pieces where `locallyModified = true`
- Implement proper tracking of what needs to be synced
- Ensure all pieces are included in sync operations

#### 17.2 Implement Pull Sync
- Add functionality to fetch all remote pieces on initial sync
- Implement periodic pull of remote changes
- Handle merging of remote changes with local data

### Day 18: Complete Bidirectional Sync

#### 18.1 Update Sync Logic
- Modify sync to send all pieces, not just modified ones
- Implement proper change tracking without filtering
- Ensure sync state is properly maintained

#### 18.2 Test Bidirectional Sync
- Verify data flows both ways between devices
- Test initial sync scenarios
- Ensure no data is lost due to filtering

## Phase 9: Multi-Device Sync with Conflict Resolution (Days 19-20)

### Day 19: Implement Conflict Resolution

#### 19.1 Last-Write-Wins Implementation
- Enhance conflict resolver with proper timestamp comparison
- Handle edge cases where timestamps are identical
- Implement version tracking for optimistic concurrency

#### 19.2 Multi-Device Testing Framework
- Set up testing scenarios for multiple devices
- Create test cases for concurrent modifications
- Verify conflict resolution works correctly

### Day 20: Multi-Device Sync Polish

#### 20.1 Sync State Management
- Implement device tracking for sync operations
- Handle sync state across multiple devices
- Ensure consistent state after conflicts

#### 20.2 Performance Optimization
- Optimize sync for multiple simultaneous devices
- Implement intelligent sync scheduling
- Reduce unnecessary sync operations

## Phase 10: Offline Mode Implementation (Days 21-22)

### Day 21: Network Monitoring

#### 21.1 Implement Network Reachability
- Replace TODO comment with actual network monitoring
- Use iOS Network framework for reachability
- Update sync status based on network state

#### 21.2 Offline Queue Enhancement
- Improve offline queue processing
- Handle network state transitions gracefully
- Implement retry logic with exponential backoff

### Day 22: Offline Mode UI/UX

#### 22.1 Offline Indicators
- Show clear offline status in UI
- Display pending changes count
- Implement offline mode notifications

#### 22.2 Offline Data Management
- Ensure full app functionality while offline
- Queue all changes for later sync
- Handle offline-to-online transitions smoothly

## Phase 11: Pull-to-Refresh Implementation (Day 23)

### Day 23: Pull-to-Refresh Feature

#### 23.1 Implement Pull-to-Refresh UI
- Add pull-to-refresh to RepertoireListView
- Add pull-to-refresh to practice views
- Implement proper loading states

#### 23.2 Refresh Logic
- Trigger full sync on pull-to-refresh
- Update UI with fresh data
- Handle errors during refresh gracefully

## Phase 12: Fix Test Mode Issues (Day 24)

### Day 24: Test Mode Authentication

#### 24.1 Fix Mock Token Handling
- Update SyncService to detect test mode
- Prevent real API calls with mock tokens
- Implement proper test mode behavior

#### 24.2 Test Environment Setup
- Create separate test configuration
- Implement mock sync service for tests
- Ensure tests don't affect production data

## Phase 13: Build System Selection (Day 25)

### Day 25: Evaluate and Implement Build System

#### 25.1 Build System Evaluation
- Evaluate Bazel for iOS builds
- Evaluate CMake for iOS builds
- Consider simple shell script alternative

#### 25.2 Implement Chosen Build System
- Set up build configuration
- Create build scripts
- Document build process
- Integrate with existing Xcode workflow

## Phase 14: Web Deployment and Safe Script (Days 26-27)

### Day 26: Fix Deployment Script

#### 26.1 Analyze Current Script Issues
- Review scripts/deploy-web.sh problems
- Understand why it removed uncommitted changes
- Identify why it included too many files in gh-pages

#### 26.2 Create Safe Deployment Script
- Implement safeguards against data loss
- Use worktree or separate clone for deployment
- Ensure only web/ contents are deployed
- Add checks to prevent IDE/process crashes

### Day 27: Web Hosting Setup

#### 27.1 GitHub Pages Configuration
- Set up proper GitHub Pages deployment
- Configure custom domain (haumana.app)
- Ensure clean gh-pages branch

#### 27.2 Legal Documents Website
- Deploy static website from web/ directory
- Verify legal documents are accessible
- Test deployment process end-to-end
- Document deployment procedure

## Timeline Summary

- **Days 1-2**: AWS infrastructure setup
- **Days 3-4**: Authentication migration to Cognito
- **Days 5-7**: Core sync service implementation
- **Days 8-9**: UI integration
- **Day 10**: Practice session sync
- **Days 11-14**: Testing and polish
- **Days 15-16**: Fix authentication and configuration (API Gateway authorizer, amplifyconfiguration.json)
- **Days 17-18**: Fix sync issues (filter and bidirectional)
- **Days 19-20**: Multi-device sync with conflict resolution
- **Days 21-22**: Offline mode implementation
- **Day 23**: Pull-to-refresh
- **Day 24**: Fix test mode issues
- **Day 25**: Build system selection
- **Days 26-27**: Web deployment and safe script

Total: 27 days