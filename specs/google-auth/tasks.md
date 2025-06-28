# Implementation Tasks - Google Authentication

## Overview

This implementation plan details the technical steps to add Google Sign-In authentication to Haumana, establishing user identity management and preparing for cloud synchronization in Milestone 5.

## Prerequisites

1. Apple Developer account with app identifier configured
2. Google Cloud Console project for OAuth 2.0
3. Privacy policy and terms of service documents prepared

## Phase 1: Project Setup and Configuration (Day 1)

- [x] Google Cloud Console Setup
  - [x] Create new project in Google Cloud Console
  - [x] Enable Google Sign-In API
  - [x] Create OAuth 2.0 Client ID for iOS
  - [x] Download configuration file (GoogleService-Info.plist)
  - [x] Note the CLIENT_ID for iOS configuration
- [x] Xcode Project Configuration
  - [x] Package Dependencies to add:
    - [x] GoogleSignIn SDK (via SPM)
    - [x] URL: https://github.com/google/GoogleSignIn-iOS
  - [x] Info.plist additions:
    - [x] CFBundleURLTypes for Google Sign-In callback
    - [x] LSApplicationQueriesSchemes if needed
- [x] Create Authentication Infrastructure
```
ios/Haumana/
├── Models/
│   └── User.swift (new)
├── Services/
│   ├── AuthenticationService.swift (new)
│   └── UserMigrationService.swift (new)
├── ViewModels/
│   └── AuthenticationViewModel.swift (new)
└── Config/
    └── GoogleService-Info.plist (new)
```

## Phase 2: Core Authentication Implementation (Day 2)

- [x] User Model
  - [x] Create Models/User.swift
  - [x] Key properties:
    - [x] `email: String`
    - [x] `displayName: String`
    - [x] `photoURL: String?`
    - [x] `lastSignIn: Date`
    - [x] `createdAt: Date`
- [x] Authentication Service
  - [x] Key methods:
    - [x] `func signIn() async`
    - [x] `func signOut() async`
    - [x] `func restorePreviousSignIn() async`
    - [x] `private func createOrUpdateUser(from googleUser: GIDGoogleUser) async`
- [x] Update Data Models
  - [x] Add user association (`var userId: String?`) to model classes:
    - [x] Models/Piece.swift
    - [x] Models/PracticeSession.swift

## Phase 3: Profile Tab UI Updates (Day 3)

- [x] Authentication ViewModel
  - [x] Create ViewModels/AuthenticationViewModel.swift
  - [x] Key methods:
    - [x] `func signIn() async`
    - [x] `func signOut()`
    - [x] `func confirmSignOut() async`
- [x] Updated Profile View
  - [x] Choose AuthenticatedProfileView or UnauthenticatedProfileView based on sign-in state
  - [x] Unconditionally show ProfileFooterView at bottom
- [ ] Profile Components
  - [x] Authenticated state with user info
    - [x] Profile photo, name, email
    - [x] Sign out button
    - [x] Data sync status (placeholder for M5)
  - [x] Unauthenticated state
    - [x] App branding
    - [x] Sign in with Google button
    - [x] Local data information
  - [ ] Shared footer
    - [ ] Privacy Policy link
    - [ ] Terms of Service link
    - [x] Send Feedback link
    - [x] App version

## Phase 4: Sign-In Screen Implementation (Day 4)

- [x] Create Sign-In Screen
  - [x] Full-screen red background (lehua color): `Color(red: 0.8, green: 0.2, blue: 0.2)`
  - [x] Centered sign-in button
  - [x] Loading overlay
- [x] Update App Entry Point
  - [x] Show either `MainTabView` or `SignInView` depending on sign-in state
  - [x] If already signed in, block rendering on restoring previous sign-in
- [x] Smart Navigation After Sign-In
  - [x] Update AuthenticationViewModel.signIn()
  - [x] Check repertoire state to show special screen for empty case
- [x] Update MainTabView
  - [x] If user just signed in and has no pieces, default to Repertoire tab
  - [x] Otherwise default to Practice tab

## Phase 5: Simplify Authenticated Experience (Day 5)

- [x] Remove Signed-Out States from Views
  - [x] All main app views can now assume the user is authenticated:
  - [x] Update PracticeTabView, RepertoireListView, HistoryTabView
  - [x] Remove any checks for authentication state
  - [x] Remove "sign in to sync" messages
  - [x] Always use authService.currentUser!.id for queries
- [x] Update Profile Tab Sign-Out Flow (ProfileTabView.swift)
  - [x] Update sign-out handling to use `authService.signOut()` in `confirmSignOut()`
- [x] Error Handling
  - [x] Network errors during sign-in (show on SignInView)
  - [x] Google Sign-In cancellation (remain on SignInView)
  - [x] Authentication token expiry (return to SignInView)
- [x] Polish Sign-In Screen
  - [x] Add app logo or title above button
  - [x] Ensure proper Google Sign-In button styling
  - [x] Test on different screen sizes
  - [x] Add subtle animation during loading

## Phase 6: Testing (Days 6-7)

- [x] Unit Tests
  - [x] AuthenticationServiceTests
    - [x] testSuccessfulSignIn()
    - [x] testSignInCancellation()
    - [x] testSignOut()
    - [x] testUserPersistence()
    - [x] testRestorePreviousSignIn()
  - [x] DataScopingTests
    - [x] testPiecesFilteredByUserId()
    - [x] testSessionsFilteredByUserId()
    - [x] testNewPieceAssignedToCurrentUser()
    - [x] testDataIsolationBetweenUsers()
- [x] UI Tests
  - [x] AuthenticationUITests
    - [x] testSplashToSignInFlow()
    - [x] testSignInFlow()
    - [x] testSignInWithEmptyRepertoire() // Should navigate to Repertoire tab
    - [x] testSignInWithExistingPieces() // Should navigate to Practice tab
    - [x] testSignOutFromProfile() // Should return to SignInView
    - [x] testSignInCancellation() // Should remain on SignInView
    - [x] testErrorMessageDisplay()
  - [x] AuthenticatedFlowTests  
    - [x] testAllTabsRequireAuthentication()
    - [x] testAddPieceAssignedToUser()
    - [x] testUserOnlySeesOwnPieces()

### 6.3 Manual Testing Checklist

- [x] Authentication Flow
  - [x] App launches with splash screen animation
  - [x] Splash screen transitions to Sign-In screen when not authenticated
  - [x] Splash screen transitions to MainTabView when authenticated
  - [x] Sign-In screen has red background (lehua color)
  - [x] Google Sign-In button is properly styled and centered
  - [x] Loading indicator shows during authentication
  - [x] Error messages display correctly on sign-in failure
- [x] Navigation After Sign-In
  - [x] First-time user (empty repertoire) lands on Repertoire tab
  - [x] Returning user (has pieces) lands on Practice tab
  - [x] Tab bar appears only after successful authentication
- [x] Data Scoping
  - [x] User only sees their own pieces in Repertoire
  - [x] Practice carousel only shows user's pieces
  - [x] New pieces are assigned to current user
  - [x] Sign out and sign in with different account shows different data
- [x] Sign-Out Flow  
  - [x] Sign-out button in Profile shows confirmation dialog
  - [x] Confirming sign-out returns to Sign-In screen
  - [x] Tab bar disappears after sign-out
  - [x] No user data visible after sign-out

## Implementation Notes

### Security Considerations
1. Never store Google tokens directly
2. Use Keychain for sensitive user data
3. Clear all user data on sign-out
4. Implement proper SSL pinning

### Performance Optimizations
1. Cache user profile photos locally
2. Lazy load user data as needed
3. Batch migrate data in background
4. Minimize authentication checks

### Edge Cases to Handle
1. User denies Google permissions
2. Network timeout during authentication
3. App killed during migration
4. Corrupted user data
5. Multiple rapid sign-in attempts

### UI/UX Guidelines
1. Follow Google Sign-In branding rules
2. Show clear loading indicators on Sign-In screen
3. Provide helpful error messages on Sign-In screen
4. No signed-out states in main app views
5. Respect system dark mode (except Sign-In screen stays red)

## Success Criteria

- [x] Sign-In screen displays with red background
- [x] Google Sign-In works reliably
- [x] User data properly scoped
- [x] Smart navigation after sign-in based on repertoire
- [x] Profile tab shows authenticated user info
- [x] Sign-out returns to Sign-In screen
- [x] No data leaks between users
- [x] All features tested on physical device

## Risk Mitigation

1. **Data Isolation**: Ensure proper userId filtering in all queries
2. **Auth Failures**: Clear error messages and retry options
3. **Privacy Concerns**: Minimal data collection, only essential user info
4. **Navigation Bugs**: Thorough testing of all auth state transitions
