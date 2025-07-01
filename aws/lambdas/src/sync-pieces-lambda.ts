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
    console.log('Sync request received:', JSON.stringify({ operation: body.operation, piecesCount: body.pieces?.length, lastSyncedAt: body.lastSyncedAt }));
    
    // Extract userId from custom authorizer context
    // The authorizer passes userId in the context
    const userId = event.requestContext.authorizer?.userId || event.requestContext.authorizer?.claims?.sub;
    
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
  const updatedPieces: Piece[] = [];
  const batchSize = 25; // DynamoDB batch write limit
  const now = new Date().toISOString();
  
  // Process in batches of 25
  for (let i = 0; i < pieces.length; i += batchSize) {
    const batch = pieces.slice(i, i + batchSize);
    const putRequests = batch.map(piece => {
      // Ensure userId matches authenticated user
      piece.userId = userId;
      piece.lastSyncedAt = now;
      
      // IMPORTANT: Update modifiedAt so other devices can detect the change
      if (!piece.modifiedAt || piece.locallyModified) {
        piece.modifiedAt = now;
        console.log(`Setting modifiedAt for piece ${piece.pieceId} to ${now}`);
      }
      
      // Generate pieceId if not present
      if (!piece.pieceId) {
        piece.pieceId = uuidv4();
      }
      
      // Update version for optimistic locking
      const oldVersion = piece.version || 0;
      piece.version = oldVersion + 1;
      console.log(`Incrementing version for piece ${piece.pieceId}: ${oldVersion} -> ${piece.version}`);
      
      // Clear locallyModified flag since it's now synced to server
      piece.locallyModified = false;
      
      uploadedPieces.push(piece.pieceId);
      updatedPieces.push(piece);
      
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
      updatedPieces,
      syncedAt: now
    })
  };
}

async function handleDownload(userId: string, lastSyncedAt?: string): Promise<APIGatewayProxyResult> {
  console.log('handleDownload called with:', { userId, lastSyncedAt });
  
  const queryParams: any = {
    TableName: PIECES_TABLE,
    KeyConditionExpression: 'userId = :userId',
    ExpressionAttributeValues: {
      ':userId': userId
    }
  };
  
  if (lastSyncedAt) {
    queryParams.FilterExpression = 'modifiedAt > :lastSync';
    queryParams.ExpressionAttributeValues[':lastSync'] = lastSyncedAt;
  }
  
  // First, let's see all pieces for debugging
  const allPiecesQuery = {
    TableName: PIECES_TABLE,
    KeyConditionExpression: 'userId = :userId',
    ExpressionAttributeValues: {
      ':userId': userId
    }
  };
  const allPiecesResponse = await docClient.send(new QueryCommand(allPiecesQuery));
  console.log(`Total pieces for user: ${allPiecesResponse.Items?.length || 0}`);
  if (allPiecesResponse.Items && allPiecesResponse.Items.length > 0) {
    console.log('Most recent piece:', {
      title: allPiecesResponse.Items[0].title,
      modifiedAt: allPiecesResponse.Items[0].modifiedAt,
      lastSyncedAt: allPiecesResponse.Items[0].lastSyncedAt
    });
  }
  
  const response = await docClient.send(new QueryCommand(queryParams));
  console.log('Query returned', response.Items?.length || 0, 'pieces');
  
  // Log first few pieces for debugging
  if (response.Items && response.Items.length > 0) {
    response.Items.slice(0, 3).forEach(item => {
      console.log('Piece:', {
        pieceId: item.pieceId,
        title: item.title,
        modifiedAt: item.modifiedAt,
        locallyModified: item.locallyModified
      });
    });
  }
  
  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    },
    body: JSON.stringify({
      serverPieces: response.Items || [],
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
  const serverPieces = serverData.serverPieces || [];
  
  // Upload client changes
  const changesToUpload = clientPieces.filter(piece => piece.locallyModified);
  console.log(`Found ${changesToUpload.length} pieces to upload`);
  let uploadedPieces: string[] = [];
  let updatedPieces: Piece[] = [];
  
  if (changesToUpload.length > 0) {
    changesToUpload.forEach(piece => {
      console.log('Uploading piece:', {
        pieceId: piece.pieceId,
        title: piece.title,
        locallyModified: piece.locallyModified,
        modifiedAt: piece.modifiedAt
      });
    });
    const uploadResponse = await handleUpload(userId, changesToUpload);
    const uploadData = JSON.parse(uploadResponse.body);
    uploadedPieces = uploadData.uploadedPieces;
    updatedPieces = uploadData.updatedPieces || [];
  }
  
  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    },
    body: JSON.stringify({
      serverPieces,
      uploadedPieces,
      updatedPieces,
      syncedAt: new Date().toISOString()
    })
  };
}