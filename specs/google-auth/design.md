# Product Requirements Document - Google Authentication (Milestone 4)

## Overview

Milestone 4 introduces user authentication to Haumana using Google Sign-In, establishing the foundation for cloud synchronization and multi-device support. This milestone focuses on secure user identity management while maintaining the app's simplicity and cultural focus.

## Goals

1. **Enable secure user authentication** through Google Sign-In
2. **Scope data to individual users** to prepare for cloud sync
3. **Create dedicated sign-in screen** as the entry point for unauthenticated users
4. **Simplify authenticated experience** by removing signed-out states from main screens
5. **Establish privacy and security foundations** for future cloud features

## User Stories

### Core Authentication
1. **As a new user**, I want to see a clean sign-in screen when I first launch the app
2. **As a returning user**, I want to stay signed in between app launches so I don't have to authenticate repeatedly
3. **As a new user with no repertoire**, I want to be taken directly to add my first piece after signing in
4. **As a signed-in user**, I want to sign out and return to the sign-in screen to protect my privacy

### Profile Management
5. **As a signed-in user**, I want to see my profile information so I know which account I'm using
6. **As a user**, I want to access privacy policy and terms of service to understand how my data is used
7. **As a beta tester**, I want to provide feedback directly from the app

### Data Management
8. **As a signed-in user**, I want my repertoire and practice data associated with my account
9. **As a user switching accounts**, I want to see only the data for my current account
10. **As a user who signs in after using the app**, I want to keep my existing local data

## Features

### 1. Sign-In Screen
- **Full-screen experience**: Red background matching lehua flower color
- **Minimal design**: Only the "Sign in with Google" button, centered
- **No tab bar**: Authentication happens before main app navigation
- **Authentication Flow**: 
  - Native Google Sign-In SDK integration
  - Smooth transition between app and authentication
  - Clear loading states during authentication
- **Post-sign-in navigation**:
  - Empty repertoire → Navigate to Repertoire tab
  - Has pieces → Navigate to Practice tab

### 2. Profile Tab (Authenticated Only)
The Profile tab is only accessible to signed-in users:

```
[Profile Tab]
├── User Profile Section
│   ├── Profile Photo
│   ├── User Name
│   └── Email Address
├── Practice Statistics
│   ├── Current Streak
│   ├── Total Sessions
│   └── Most Practiced Piece
├── Account Actions
│   └── [Sign Out] button
├── Data Status
│   └── "Data synced with your account" (prep for M5)
└── Links Section
    ├── Privacy Policy
    ├── Terms of Service
    └── Send Feedback
```

**Sign-out behavior**: Confirmation dialog → Navigate to Sign-In Screen

### 3. User-Scoped Data
- **User Context**: Add userId field to Piece and PracticeSession models
- **Data Filtering**: Show only current user's data when signed in
- **No guest mode**: Authentication is required to use the app
- **First-time user flow**: Detect empty repertoire and navigate to Repertoire tab

### 4. Privacy & Legal (Deferred to Post-Launch)
- **Note**: Privacy policy and terms of service links are included in the UI but commented out
- **Rationale**: Not needed for private gift release, will be added before public App Store release
- **Data Collection**: Minimal - only Google user ID, email, display name, and photo URL

### 5. App Navigation Structure
- **Entry point**: Sign-In Screen (no tab bar)
- **Main app**: Tab bar with Practice, Repertoire, History, Profile
- **Authentication gate**: All features require sign-in
- **Smart landing**: Navigate based on repertoire state after sign-in

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
- **Sign-In Screen**: Full-screen red (#FF0000 or lehua-appropriate shade)
- **Google Branding**: Follow Google Sign-In branding guidelines
- **Button styling**: Prominent white button with Google branding
- **Loading States**: Overlay during authentication
- **Error States**: Clear messaging for authentication failures

### Interaction Patterns
- **Sign-In Flow**:
  1. App launch → Sign-In Screen
  2. Tap "Sign in with Google"
  3. Native Google authentication sheet
  4. Return to app with loading state
  5. Check repertoire:
     - Empty → Navigate to Repertoire tab
     - Has pieces → Navigate to Practice tab
  
- **Sign-Out Flow**:
  1. Profile tab → Tap "Sign Out"
  2. Confirmation alert: "Sign out of Haumana?"
  3. Clear authentication
  4. Navigate to Sign-In Screen

### Edge Cases
- **Network Errors**: Show error on Sign-In Screen with retry
- **Cancelled Sign-In**: Remain on Sign-In Screen
- **Account Switching**: Clear previous user data completely
- **App killed during auth**: Return to Sign-In Screen on restart

## Success Metrics

1. **Authentication Success Rate**: >95% successful sign-ins
2. **User Adoption**: >60% of users choose to sign in
3. **Session Persistence**: <1% unexpected sign-outs
4. **Beta Feedback**: Positive feedback on authentication flow
5. **Privacy Compliance**: Zero privacy policy violations

## Development Checklist

### Setup
- [x] Add Google Sign-In SDK dependency
- [x] Configure Google Cloud project
- [x] Add OAuth client ID for iOS
- [x] Update Info.plist with URL schemes

### Implementation
- [x] Create AuthService with Google Sign-In
- [x] Build AuthViewModel for state management
- [x] Update Profile tab UI for authenticated state only
- [x] Add userId to data models
- [x] Implement data filtering by user
- [x] Add sign-out confirmation flow
- [x] Create dedicated Sign-In screen

### Testing
- [x] Unit tests for AuthService
- [x] UI tests for sign-in/sign-out flows
- [x] Test data isolation between users
- [x] Test account switching
- [x] All manual tests passed

### Deployment
- [x] Test on physical device
- [x] Verify all navigation flows

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
  - Sign-In Screen with Google authentication
  - Updated Profile tab (authenticated only)
  - Smart navigation after sign-in
  - Privacy/Terms pages