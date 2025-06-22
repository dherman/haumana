import { APIGatewayTokenAuthorizerEvent, APIGatewayAuthorizerResult, Context } from 'aws-lambda';
import { OAuth2Client } from 'google-auth-library';

const googleClient = new OAuth2Client();

// Google OAuth client IDs
const GOOGLE_WEB_CLIENT_ID = process.env.GOOGLE_WEB_CLIENT_ID || '872799888201-51c9jb50nkdl2cl4vu8fp9h5cs7tdmuj.apps.googleusercontent.com';
const GOOGLE_IOS_CLIENT_ID = '872799888201-rdv0c48nup16mo4b19jjred0jgpjoltc.apps.googleusercontent.com';

export const handler = async (
  event: APIGatewayTokenAuthorizerEvent,
  context: Context
): Promise<APIGatewayAuthorizerResult> => {
  console.log('Authorizer event:', JSON.stringify(event));
  
  // Extract token from Authorization header
  const token = event.authorizationToken?.replace('Bearer ', '');
  
  if (!token) {
    console.log('No token provided');
    throw new Error('Unauthorized');
  }
  
  try {
    // Verify the Google ID token
    const ticket = await googleClient.verifyIdToken({
      idToken: token,
      audience: [GOOGLE_WEB_CLIENT_ID, GOOGLE_IOS_CLIENT_ID]
    });
    
    const payload = ticket.getPayload();
    if (!payload) {
      console.log('No payload in token');
      throw new Error('Unauthorized');
    }
    
    console.log('Token verified for user:', payload.email);
    
    // Extract user information
    const userId = payload.sub; // Google user ID
    const email = payload.email;
    
    // Create IAM policy
    const policy: APIGatewayAuthorizerResult = {
      principalId: userId,
      policyDocument: {
        Version: '2012-10-17',
        Statement: [
          {
            Action: 'execute-api:Invoke',
            Effect: 'Allow',
            Resource: event.methodArn.split('/').slice(0, 2).join('/') + '/*'
          }
        ]
      },
      // Pass user context to Lambda functions
      context: {
        userId: userId,
        email: email || '',
        name: payload.name || '',
        picture: payload.picture || ''
      }
    };
    
    console.log('Authorization successful for user:', email);
    return policy;
    
  } catch (error) {
    console.error('Token verification failed:', error);
    throw new Error('Unauthorized');
  }
};