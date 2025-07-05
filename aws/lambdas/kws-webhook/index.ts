import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand, UpdateCommand } from '@aws-sdk/lib-dynamodb';
import * as crypto from 'crypto';

const dynamoClient = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(dynamoClient);

const USERS_TABLE = process.env.USERS_TABLE || 'haumana-users';
const KWS_WEBHOOK_SECRET = process.env.KWS_WEBHOOK_SECRET || '';

interface KWSWebhookPayload {
  event: string;
  userId: string;
  parentEmail: string;
  permissions: string[];
  timestamp: string;
}

/**
 * Validates the webhook signature from KWS
 */
function validateWebhookSignature(
  body: string,
  signature: string,
  secret: string
): boolean {
  if (!secret) {
    console.error('KWS_WEBHOOK_SECRET not configured');
    return false;
  }

  // KWS typically uses HMAC-SHA256 for webhook signatures
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(body)
    .digest('hex');

  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSignature)
  );
}

/**
 * Updates the user's parent consent status in DynamoDB
 */
async function updateParentConsentStatus(
  userId: string,
  status: 'approved' | 'denied',
  parentEmail: string,
  permissions: string[]
): Promise<void> {
  const now = new Date().toISOString();

  await docClient.send(
    new UpdateCommand({
      TableName: USERS_TABLE,
      Key: {
        PK: `USER#${userId}`,
        SK: `USER#${userId}`
      },
      UpdateExpression: `
        SET parentConsentStatus = :status,
            parentEmail = :parentEmail,
            parentConsentDate = :date,
            parentConsentPermissions = :permissions,
            modifiedAt = :now
      `,
      ExpressionAttributeValues: {
        ':status': status,
        ':parentEmail': parentEmail,
        ':date': now,
        ':permissions': permissions,
        ':now': now
      }
    })
  );
}

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  console.log('KWS Webhook received:', {
    headers: event.headers,
    body: event.body
  });

  try {
    // Validate request has body
    if (!event.body) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Missing request body' })
      };
    }

    // Get signature from query string or headers
    const signature = event.queryStringParameters?.signature || 
                     event.headers['x-kws-signature'] || '';

    // Validate webhook signature
    if (!validateWebhookSignature(event.body, signature, KWS_WEBHOOK_SECRET)) {
      console.error('Invalid webhook signature');
      return {
        statusCode: 401,
        body: JSON.stringify({ error: 'Invalid signature' })
      };
    }

    // Parse webhook payload
    const payload: KWSWebhookPayload = JSON.parse(event.body);
    console.log('Webhook payload:', payload);

    // Handle different event types
    switch (payload.event) {
      case 'parent.verified':
      case 'consent.approved':
        await updateParentConsentStatus(
          payload.userId,
          'approved',
          payload.parentEmail,
          payload.permissions
        );
        console.log(`Parent consent approved for user ${payload.userId}`);
        break;

      case 'consent.denied':
        await updateParentConsentStatus(
          payload.userId,
          'denied',
          payload.parentEmail,
          []
        );
        console.log(`Parent consent denied for user ${payload.userId}`);
        break;

      default:
        console.log(`Unhandled event type: ${payload.event}`);
    }

    // Return success response
    return {
      statusCode: 200,
      body: JSON.stringify({ 
        message: 'Webhook processed successfully',
        event: payload.event 
      })
    };

  } catch (error) {
    console.error('Error processing webhook:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ 
        error: 'Internal server error',
        details: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};