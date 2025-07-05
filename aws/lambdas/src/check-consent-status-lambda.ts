import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);
const USERS_TABLE = process.env.USERS_TABLE || 'haumana-users';

interface ConsentStatusResponse {
  status: 'pending' | 'approved' | 'denied';
  parentEmail?: string;
  approvedAt?: string;
  deniedAt?: string;
}

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    console.log('Check consent status request received');
    
    // Extract userId from path parameters
    const userId = event.pathParameters?.userId;
    
    if (!userId) {
      return {
        statusCode: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: JSON.stringify({ error: 'userId is required' })
      };
    }
    
    // Get consent status from DynamoDB
    const getCommand = new GetCommand({
      TableName: USERS_TABLE,
      Key: {
        PK: `USER#${userId}`,
        SK: 'CONSENT'
      }
    });
    
    const result = await docClient.send(getCommand);
    console.log('DynamoDB result:', JSON.stringify(result.Item));
    
    if (!result.Item) {
      // No consent record found, return pending status
      return {
        statusCode: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: JSON.stringify({
          status: 'pending'
        } as ConsentStatusResponse)
      };
    }
    
    // Return the consent status
    const response: ConsentStatusResponse = {
      status: result.Item.status || 'pending',
      parentEmail: result.Item.parentEmail,
      approvedAt: result.Item.approvedAt,
      deniedAt: result.Item.deniedAt
    };
    
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify(response)
    };
    
  } catch (error) {
    console.error('Error checking consent status:', error);
    
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({ error: 'Internal server error' })
    };
  }
};