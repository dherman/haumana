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
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
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
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          },
          body: JSON.stringify({ error: 'Invalid operation' })
        };
    }
  } catch (error) {
    console.error('Lambda error:', error);
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
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
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    },
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
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    },
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
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    },
    body: JSON.stringify({
      serverPieces,
      uploadedCount,
      syncedAt: new Date().toISOString()
    })
  };
}