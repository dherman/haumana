# Cognito Hybrid Authentication Migration Plan

## Overview

This document outlines the migration from Cognito Hosted UI to a hybrid approach using Google Sign-In SDK with Cognito Identity Federation. This change addresses the automatic re-authentication issue that occurs with federated sign-out through Cognito Hosted UI.

## Problem Statement

When users sign out through Cognito Hosted UI with federated Google authentication:
1. The sign-out redirect triggers the Cognito Hosted UI
2. Browser cookies from Google persist
3. Users are automatically signed back in without consent
4. This creates a poor user experience and confusion

## Solution: Hybrid Authentication

### Architecture

```
Current Flow:
App → Cognito Hosted UI → Google OAuth → Cognito User Pool → AWS Services

New Flow:
App → Google Sign-In SDK → Cognito Identity Pool → AWS Services
```

### Key Components

1. **Google Sign-In SDK**: Handles OAuth flow natively in the app
2. **Cognito Identity Pool**: Federates Google tokens for AWS credentials
3. **Cognito User Pool**: Still used for user attributes and management
4. **Custom Token Exchange**: Links Google identity to Cognito identity

## Implementation Plan

### Phase 1: Setup and Dependencies (Day 1)

1. **Add Google Sign-In SDK**
   - Add Swift Package: `https://github.com/google/GoogleSignIn-iOS`
   - Configure Info.plist with Google OAuth credentials
   - Add URL scheme for Google Sign-In callbacks

2. **Update AWS Configuration**
   - Configure Cognito Identity Pool to accept Google tokens
   - Set up identity pool role mappings
   - Update IAM policies for federated access

3. **Create Migration Service**
   - New `HybridAuthenticationService` class
   - Implements `AuthenticationServiceProtocol`
   - Handles both Google SDK and Cognito operations

### Phase 2: Authentication Flow Implementation (Days 2-3)

1. **Sign-In Flow**
   ```swift
   class HybridAuthenticationService: AuthenticationServiceProtocol {
       func signIn(presenting viewController: UIViewController) async throws {
           // 1. Google Sign-In
           guard let presentingWindow = viewController.view.window else {
               throw AuthError.service("No window available", "")
           }
           
           let result = try await GIDSignIn.sharedInstance.signIn(
               withPresenting: viewController
           )
           
           // 2. Get Google ID token
           guard let idToken = result.user.idToken?.tokenString else {
               throw AuthError.service("No ID token from Google", "")
           }
           
           // 3. Exchange for Cognito credentials
           let credentials = try await exchangeTokenForCredentials(
               provider: "accounts.google.com",
               token: idToken
           )
           
           // 4. Create/update user in User Pool via Lambda
           let cognitoUser = try await createOrUpdateCognitoUser(
               googleUser: result.user,
               credentials: credentials
           )
           
           // 5. Update local user model
           await updateLocalUser(from: cognitoUser)
       }
   }
   ```

2. **Sign-Out Flow**
   ```swift
   func signOut() async {
       // 1. Clear local state immediately
       currentUser = nil
       isSignedIn = false
       
       // 2. Sign out from Google (no redirect!)
       GIDSignIn.sharedInstance.signOut()
       
       // 3. Clear Cognito credentials
       try? await clearCognitoCredentials()
       
       // 4. Notify listeners
       NotificationCenter.default.post(name: .authStateChanged, object: nil)
   }
   ```

3. **Token Exchange Logic**
   ```swift
   private func exchangeTokenForCredentials(
       provider: String,
       token: String
   ) async throws -> AWSCredentials {
       // Configure credentials provider
       let credentialsProvider = AWSCognitoCredentialsProvider(
           regionType: .USWest2,
           identityPoolId: AppConstants.cognitoIdentityPoolId,
           identityProviderManager: nil
       )
       
       // Set the Google token
       credentialsProvider.logins = [provider: token]
       
       // Get AWS credentials
       return try await withCheckedThrowingContinuation { continuation in
           credentialsProvider.credentials().continueWith { task in
               if let error = task.error {
                   continuation.resume(throwing: error)
               } else if let credentials = task.result {
                   continuation.resume(returning: credentials)
               }
               return nil
           }
       }
   }
   ```

### Phase 3: User Management Bridge (Days 3-4)

1. **Lambda Function for User Sync**
   - Triggered by Cognito Identity Pool authentication
   - Creates/updates corresponding User Pool entry
   - Syncs Google profile data to User Pool attributes
   - Returns user metadata to app

2. **Update User Model**
   - Add Google-specific fields if needed
   - Maintain backward compatibility
   - Handle migration of existing users

### Phase 4: Migration and Testing (Days 5-6)

1. **Migration Strategy**
   - Feature flag to toggle between old and new auth
   - Gradual rollout to test with subset of users
   - Fallback mechanism if issues arise

2. **Testing Scenarios**
   - New user registration
   - Existing user sign-in
   - Sign-out flow (verify no auto-signin)
   - Token refresh
   - Offline scenarios
   - Multiple device scenarios

3. **Error Handling**
   - Network failures
   - Google SDK errors
   - Cognito federation errors
   - Token expiration

### Phase 5: Cleanup (Day 7)

1. **Remove Old Code**
   - Remove Cognito Hosted UI configuration
   - Clean up `AmplifyAuthenticationService`
   - Update `amplifyconfiguration.json`

2. **Documentation**
   - Update user guides
   - Document new auth flow
   - Update troubleshooting guides

## Benefits

1. **No Automatic Re-authentication**: Sign-out properly clears Google session
2. **Better UX**: Native sign-in experience without web redirects
3. **More Control**: Direct handling of auth states and errors
4. **Maintains Security**: Still uses Cognito for AWS access control

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Google SDK breaking changes | Pin SDK version, monitor deprecations |
| Token sync issues | Implement retry logic with exponential backoff |
| User Pool sync failures | Queue failed syncs for retry |
| Increased complexity | Comprehensive logging and monitoring |

## Success Criteria

1. Users can sign out without automatic re-authentication
2. Sign-in/out flows complete in < 3 seconds
3. All existing user data is preserved
4. No degradation in security posture
5. Error rate < 0.1% for auth operations

## Timeline

- Day 1: Setup and dependencies
- Days 2-3: Core authentication implementation
- Days 3-4: User management bridge
- Days 5-6: Testing and migration
- Day 7: Cleanup and documentation

Total: 7 working days

## Dependencies

1. Google OAuth 2.0 client configuration
2. Cognito Identity Pool with Google provider
3. Lambda function for user synchronization
4. Updated IAM roles and policies

## Rollback Plan

If critical issues arise:
1. Use feature flag to revert to Hosted UI
2. Monitor error rates and user feedback
3. Fix issues before re-attempting migration
4. Maintain both code paths until stable