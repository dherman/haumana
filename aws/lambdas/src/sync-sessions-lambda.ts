import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, BatchWriteCommand, QueryCommand } from '@aws-sdk/lib-dynamodb';

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
  lastSyncedAt?: string;
}

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    const body: SyncSessionsRequest = JSON.parse(event.body || '{}');
    
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
    
    const sessions = body.sessions || [];
    const uploadedSessions: string[] = [];
    const batchSize = 25; // DynamoDB batch write limit
    const now = new Date().toISOString();
    
    // First, query for existing sessions to download
    const serverSessions: PracticeSession[] = [];
    let exclusiveStartKey: any = undefined;
    
    do {
      const queryResult = await docClient.send(new QueryCommand({
        TableName: SESSIONS_TABLE,
        KeyConditionExpression: 'pk = :pk',
        ExpressionAttributeValues: {
          ':pk': `USER#${userId}`
        },
        ExclusiveStartKey: exclusiveStartKey
      }));
      
      if (queryResult.Items) {
        for (const item of queryResult.Items) {
          // Extract session data from DynamoDB item
          serverSessions.push({
            sessionId: item.sessionId,
            userId: item.userId,
            pieceId: item.pieceId,
            startedAt: item.startedAt,
            endedAt: item.endedAt,
            endedAtSource: item.endedAtSource,
            createdAt: item.createdAt
          });
        }
      }
      
      exclusiveStartKey = queryResult.LastEvaluatedKey;
    } while (exclusiveStartKey);
    
    // Process uploaded sessions in batches of 25
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
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({
        uploadedSessions,
        serverSessions,
        syncedAt: now
      })
    };
    
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