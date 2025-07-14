import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand, QueryCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const USERS_TABLE = process.env.USERS_TABLE || 'haumana-users';
const PIECES_TABLE = process.env.PIECES_TABLE || 'haumana-pieces';
const SESSIONS_TABLE = process.env.SESSIONS_TABLE || 'haumana-sessions';

interface UserData {
  PK: string;
  SK: string;
  userId: string;
  email: string;
  displayName?: string;
  photoUrl?: string;
  createdAt: string;
  isMinor?: boolean;
  parentConsentStatus?: string;
  [key: string]: any;
}

interface PieceData {
  userId: string;
  pieceId: string;
  title: string;
  category: string;
  lyrics: string;
  language?: string;
  author?: string;
  sourceUrl?: string;
  notes?: string;
  createdAt: string;
  modifiedAt: string;
  [key: string]: any;
}

interface SessionData {
  pk: string;
  sk: string;
  sessionId: string;
  userId: string;
  pieceId: string;
  startedAt: string;
  endedAt?: string;
  [key: string]: any;
}

interface ExportData {
  exportDate: string;
  exportVersion: string;
  user: UserData | null;
  pieces: PieceData[];
  practiceSessions: SessionData[];
}

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  console.log('Export user data request:', JSON.stringify(event, null, 2));
  
  const userId = event.pathParameters?.userId;
  
  if (!userId) {
    return {
      statusCode: 400,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({ error: 'User ID is required' })
    };
  }
  
  // Verify the requesting user matches the user ID (from authorizer)
  const requestingUserId = event.requestContext?.authorizer?.userId || event.requestContext?.authorizer?.principalId;
  
  console.log('Authorization check - requesting user:', requestingUserId, 'requested user:', userId);
  
  if (requestingUserId !== userId) {
    return {
      statusCode: 403,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({ error: 'Unauthorized to export this user\'s data' })
    };
  }
  
  try {
    // Fetch all user data in parallel
    const [userData, piecesData, sessionsData] = await Promise.all([
      getUserData(userId),
      getUserPieces(userId),
      getUserSessions(userId)
    ]);
    
    // Check if user is a minor and has parental consent
    if (userData?.isMinor && userData?.parentConsentStatus !== 'approved') {
      return {
        statusCode: 403,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: JSON.stringify({ 
          error: 'Data export requires parental consent',
          code: 'PARENTAL_CONSENT_REQUIRED'
        })
      };
    }
    
    // Compile export data
    const exportData: ExportData = {
      exportDate: new Date().toISOString(),
      exportVersion: '1.0',
      user: userData,
      pieces: piecesData,
      practiceSessions: sessionsData
    };
    
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Content-Disposition': `attachment; filename="haumana-export-${Date.now()}.json"`
      },
      body: JSON.stringify(exportData, null, 2)
    };
    
  } catch (error) {
    console.error('Error exporting user data:', error);
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({ error: 'Failed to export user data' })
    };
  }
};

async function getUserData(userId: string): Promise<UserData | null> {
  const command = new GetCommand({
    TableName: USERS_TABLE,
    Key: { 
      PK: `USER#${userId}`,
      SK: 'PROFILE'
    }
  });
  
  const result = await docClient.send(command);
  return result.Item as UserData | null;
}

async function getUserPieces(userId: string): Promise<PieceData[]> {
  const command = new QueryCommand({
    TableName: PIECES_TABLE,
    KeyConditionExpression: 'userId = :userId',
    ExpressionAttributeValues: {
      ':userId': userId
    }
  });
  
  const result = await docClient.send(command);
  return (result.Items || []) as PieceData[];
}

async function getUserSessions(userId: string): Promise<SessionData[]> {
  const command = new QueryCommand({
    TableName: SESSIONS_TABLE,
    KeyConditionExpression: 'pk = :pk',
    ExpressionAttributeValues: {
      ':pk': `USER#${userId}`
    }
  });
  
  const result = await docClient.send(command);
  return (result.Items || []) as SessionData[];
}