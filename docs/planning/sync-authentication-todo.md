# Sync Authentication TODO

## Current State

We've implemented the core sync infrastructure for Milestone 5, including:
- ✅ SyncService with status tracking and UI
- ✅ Sync status indicators in Repertoire and Profile tabs
- ✅ Data models updated with sync properties
- ✅ Offline queue management structure

However, the actual sync functionality is temporarily disabled because our API Gateway is configured to use Cognito User Pool authorization, but our hybrid authentication approach doesn't actually sign users into Cognito through Amplify.

## The Problem

1. API Gateway expects Cognito User Pool JWT tokens in the Authorization header
2. Our hybrid auth approach uses Google Sign-In SDK directly
3. We sync users to Cognito User Pool via Lambda, but don't get back JWT tokens
4. Without valid Cognito tokens, API calls get 401 Unauthorized errors

## Solution Options

### Option 1: Custom Authorizer (Recommended)
Create a Lambda authorizer that validates Google ID tokens directly:
1. Update API Gateway to use a custom authorizer
2. Authorizer validates Google ID tokens
3. Extracts user ID and passes to backend Lambda functions
4. No dependency on Cognito JWT tokens

### Option 2: Get Cognito Tokens
Modify the auth-sync Lambda to return Cognito tokens:
1. After creating/updating user in Cognito, generate admin tokens
2. Return tokens to iOS app
3. Store and use tokens for API calls
4. Handle token refresh

### Option 3: API Key + User Context
Use API keys for authorization and pass user context:
1. Change API Gateway to use API key authorization
2. Pass user ID in custom header
3. Less secure but simpler to implement

## Implementation Steps for Option 1

1. Create Lambda authorizer function:
   ```typescript
   export const handler = async (event) => {
     const token = event.authorizationToken;
     // Validate Google ID token
     // Extract user ID
     // Return IAM policy
   };
   ```

2. Update CDK stack to use custom authorizer:
   ```typescript
   const authorizer = new apigateway.TokenAuthorizer(this, 'GoogleTokenAuthorizer', {
     handler: authorizerFunction,
     identitySource: 'method.request.header.Authorization'
   });
   ```

3. Update iOS SyncService to include Google ID token:
   ```swift
   private func makeAuthenticatedRequest(to path: String, body: Data) async throws -> Data {
     guard let idToken = await getGoogleIDToken() else {
       throw SyncError.noAuthToken
     }
     
     var request = URLRequest(url: URL(string: "\(apiEndpoint)\(path)")!)
     request.httpMethod = "POST"
     request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
     request.setValue("application/json", forHTTPHeaderField: "Content-Type")
     request.httpBody = body
     
     let (data, response) = try await URLSession.shared.data(for: request)
     // Handle response
   }
   ```

## Next Steps

1. Decide on authorization approach
2. Update API Gateway configuration
3. Implement authorization solution
4. Update iOS SyncService to use proper authentication
5. Test multi-device sync scenarios

## Temporary Workaround

The sync UI is fully functional but sync operations are simulated. The app will:
- Show sync status changes
- Track pending changes
- Display last sync time
- But not actually sync data to the cloud

This allows testing the UI/UX while we implement proper authentication.