# Milestone 4: Google Authentication PRD

## Overview

Milestone 4 introduces user authentication to Haumana using Google Sign-In, establishing the foundation for cloud synchronization and multi-device support. This milestone focuses on secure user identity management while maintaining the app's simplicity and cultural focus.

## Goals

1. **Enable secure user authentication** through Google Sign-In
2. **Scope data to individual users** to prepare for cloud sync
3. **Maintain offline functionality** for users who choose not to sign in
4. **Deploy to TestFlight** for beta testing with real users
5. **Establish privacy and security foundations** for future cloud features

## User Stories

### Core Authentication
1. **As a new user**, I want to sign in with my Google account so that my data can be saved securely
2. **As a returning user**, I want to stay signed in between app launches so I don't have to authenticate repeatedly
3. **As a privacy-conscious user**, I want to use the app without signing in and keep my data local-only
4. **As a signed-in user**, I want to sign out to protect my privacy on shared devices

### Profile Management
5. **As a signed-in user**, I want to see my profile information so I know which account I'm using
6. **As a user**, I want to access privacy policy and terms of service to understand how my data is used
7. **As a beta tester**, I want to provide feedback directly from the app

### Data Management
8. **As a signed-in user**, I want my repertoire and practice data associated with my account
9. **As a user switching accounts**, I want to see only the data for my current account
10. **As a user who signs in after using the app**, I want to keep my existing local data

## Features

### 1. Google Sign-In Integration
- **Sign-In Button**: Prominent but not intrusive placement on Profile tab
- **Authentication Flow**: 
  - Native Google Sign-In SDK integration
  - Smooth transition between app and authentication
  - Clear loading states during authentication
- **Account Display**: Show user's name, email, and profile photo when signed in
- **Sign-Out**: Clear option to sign out with confirmation dialog

### 2. Profile Tab Enhancement
Transform the existing Profile tab into a comprehensive account management center:

#### Signed-Out State
```
[Profile Tab - Signed Out]
├── App Logo & Name
├── Sign In Section
│   ├── "Sign in to sync across devices"
│   └── [Sign in with Google] button
├── Local Data Info
│   └── "Your data is stored locally on this device"
└── Links Section
    ├── Privacy Policy
    ├── Terms of Service
    └── Send Feedback
```

#### Signed-In State
```
[Profile Tab - Signed In]
├── User Profile Section
│   ├── Profile Photo
│   ├── User Name
│   └── Email Address
├── Account Actions
│   └── [Sign Out] button
├── Data Status
│   └── "Data synced with your account" (prep for M5)
└── Links Section
    ├── Privacy Policy
    ├── Terms of Service
    └── Send Feedback
```

### 3. User-Scoped Data
- **Data Migration**: Associate existing local pieces with signed-in user
- **User Context**: Add userId field to Piece and PracticeSession models
- **Data Filtering**: Show only current user's data when signed in
- **Guest Mode**: Continue supporting local-only data for non-authenticated users

### 4. Privacy & Legal
- **Privacy Policy**: Link to external privacy policy webpage
- **Terms of Service**: Link to external terms of service webpage
- **Data Disclosure**: Clear messaging about what data is collected
- **Compliance**: COPPA and GDPR considerations for data handling

### 5. TestFlight Deployment
- **Beta Program**: Set up TestFlight for beta testing
- **Feedback Integration**: In-app feedback link for beta testers
- **Version Management**: Clear versioning for beta releases

## Technical Implementation

### Authentication Architecture
```
┌─────────────────┐
│   SwiftUI App   │
├─────────────────┤
│ AuthViewModel   │
├─────────────────┤
│ AuthService     │
├─────────────────┤
│ Google Sign-In  │
│      SDK        │
└─────────────────┘
```

### Key Components
1. **AuthService**: Manages authentication state and Google Sign-In
2. **AuthViewModel**: Handles UI state for authentication flows
3. **UserContext**: Provides current user context throughout app
4. **Migration Service**: Handles existing data association with new users

### Data Model Updates
```swift
// Updated Piece model
@Model
final class Piece {
    // Existing fields...
    var userId: String? // nil for local-only data
}

// New User model (local cache)
@Model
final class User {
    var id: String // Google user ID
    var email: String
    var displayName: String
    var photoURL: String?
    var lastSignIn: Date
}
```

## UX Design

### Visual Design
- **Google Branding**: Follow Google Sign-In branding guidelines
- **Profile Photos**: Circular crop with fallback initials
- **Loading States**: Skeleton screens during authentication
- **Error States**: Clear messaging for authentication failures

### Interaction Patterns
- **Sign-In Flow**:
  1. Tap "Sign in with Google"
  2. Native Google authentication sheet
  3. Return to app with loading state
  4. Show success and update UI
  
- **Sign-Out Flow**:
  1. Tap "Sign Out"
  2. Confirmation alert: "Sign out of Haumana?"
  3. Clear authentication and show signed-out state

### Edge Cases
- **Network Errors**: Graceful handling with retry options
- **Cancelled Sign-In**: Return to previous state cleanly
- **Account Switching**: Clear data separation between accounts
- **Migration Conflicts**: Strategy for handling existing local data

## Success Metrics

1. **Authentication Success Rate**: >95% successful sign-ins
2. **User Adoption**: >60% of users choose to sign in
3. **Session Persistence**: <1% unexpected sign-outs
4. **Beta Feedback**: Positive feedback on authentication flow
5. **Privacy Compliance**: Zero privacy policy violations

## Development Checklist

### Setup
- [ ] Add Google Sign-In SDK dependency
- [ ] Configure Google Cloud project
- [ ] Add OAuth client ID for iOS
- [ ] Update Info.plist with URL schemes

### Implementation
- [ ] Create AuthService with Google Sign-In
- [ ] Build AuthViewModel for state management
- [ ] Update Profile tab UI for both states
- [ ] Add userId to data models
- [ ] Implement data filtering by user
- [ ] Create migration service for existing data
- [ ] Add sign-out confirmation flow

### Testing
- [ ] Unit tests for AuthService
- [ ] UI tests for sign-in/sign-out flows
- [ ] Test data migration scenarios
- [ ] Verify offline functionality preserved
- [ ] Test account switching

### Deployment
- [ ] Create privacy policy webpage
- [ ] Create terms of service webpage
- [ ] Set up TestFlight
- [ ] Configure beta testing group
- [ ] Prepare beta testing instructions

## Future Considerations

This milestone lays the groundwork for:
- **Milestone 5**: Cloud synchronization with AWS
- **Multi-device Support**: Seamless data access across devices
- **Sharing Features**: Share pieces with other users
- **Teacher/Student Connections**: Account-based relationships
- **Usage Analytics**: Aggregate practice data (with consent)

## Risks & Mitigations

1. **Risk**: Users reluctant to sign in
   - **Mitigation**: Clear value proposition, optional sign-in, strong privacy messaging

2. **Risk**: Authentication failures impact app usage
   - **Mitigation**: Robust offline mode, graceful error handling

3. **Risk**: Data migration causes data loss
   - **Mitigation**: Backup before migration, reversible process

4. **Risk**: Privacy concerns with Google Sign-In
   - **Mitigation**: Minimal data collection, clear privacy policy

## Timeline

- **Duration**: 1 week
- **Dependencies**: Completion of Milestone 3
- **Deliverables**: 
  - Functional Google Sign-In
  - Updated Profile tab
  - TestFlight beta release
  - Privacy/Terms pages