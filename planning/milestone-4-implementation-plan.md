# Milestone 4: Google Authentication - Implementation Plan

## Overview

This implementation plan details the technical steps to add Google Sign-In authentication to Haumana, establishing user identity management and preparing for cloud synchronization in Milestone 5.

## Prerequisites

1. Apple Developer account with app identifier configured
2. Google Cloud Console project for OAuth 2.0
3. TestFlight configured for beta distribution
4. Privacy policy and terms of service documents prepared

## Phase 1: Project Setup and Configuration (Day 1)

### 1.1 Google Cloud Console Setup
```
1. Create new project in Google Cloud Console
2. Enable Google Sign-In API
3. Create OAuth 2.0 Client ID for iOS
4. Download configuration file (GoogleService-Info.plist)
5. Note the CLIENT_ID for iOS configuration
```

### 1.2 Xcode Project Configuration
```swift
// Package Dependencies to add:
// - GoogleSignIn SDK (via SPM)
// - URL: https://github.com/google/GoogleSignIn-iOS

// Info.plist additions:
// - CFBundleURLTypes for Google Sign-In callback
// - LSApplicationQueriesSchemes if needed
```

### 1.3 Create Authentication Infrastructure
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

### 2.1 User Model
```swift
// Models/User.swift
import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: String
    var email: String
    var displayName: String
    var photoURL: String?
    var lastSignIn: Date
    var createdAt: Date
    
    init(id: String, email: String, displayName: String, photoURL: String? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.lastSignIn = Date()
        self.createdAt = Date()
    }
}
```

### 2.2 Authentication Service
```swift
// Services/AuthenticationService.swift
import GoogleSignIn
import SwiftUI

@MainActor
class AuthenticationService: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: AuthenticationError?
    
    private let modelContext: ModelContext
    
    func signIn() async
    func signOut() async
    func restorePreviousSignIn() async
    private func createOrUpdateUser(from googleUser: GIDGoogleUser) async
}
```

### 2.3 Update Data Models
```swift
// Models/Piece.swift - Add user association
extension Piece {
    var userId: String?
}

// Models/PracticeSession.swift - Add user association
extension PracticeSession {
    var userId: String?
}
```

## Phase 3: Profile Tab UI Updates (Day 3)

### 3.1 Authentication ViewModel
```swift
// ViewModels/AuthenticationViewModel.swift
import SwiftUI
import Observation

@Observable
class AuthenticationViewModel {
    var user: User?
    var isSignedIn: Bool { user != nil }
    var isLoading = false
    var showingSignOutConfirmation = false
    var errorMessage: String?
    
    private let authService: AuthenticationService
    
    func signIn() async
    func signOut()
    func confirmSignOut() async
}
```

### 3.2 Updated Profile View
```swift
// Views/ProfileTabView.swift
struct ProfileTabView: View {
    @Environment(AuthenticationViewModel.self) private var authViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if authViewModel.isSignedIn {
                        AuthenticatedProfileView()
                    } else {
                        UnauthenticatedProfileView()
                    }
                    
                    // Common footer with links
                    ProfileFooterView()
                }
            }
            .navigationTitle("Profile")
        }
    }
}
```

### 3.3 Profile Components
```swift
// Authenticated state with user info
struct AuthenticatedProfileView: View {
    // Profile photo, name, email
    // Sign out button
    // Data sync status (placeholder for M5)
}

// Unauthenticated state
struct UnauthenticatedProfileView: View {
    // App branding
    // Sign in with Google button
    // Local data information
}

// Shared footer
struct ProfileFooterView: View {
    // Privacy Policy link
    // Terms of Service link
    // Send Feedback link
    // App version
}
```

## Phase 4: Data Migration and Scoping (Day 4)

### 4.1 User Migration Service
```swift
// Services/UserMigrationService.swift
class UserMigrationService {
    private let modelContext: ModelContext
    
    // Migrate existing local pieces to authenticated user
    func migrateLocalDataToUser(_ userId: String) async throws
    
    // Filter queries by current user
    func piecesForCurrentUser() -> [Piece]
    
    // Handle account switching
    func handleUserChange(from oldUserId: String?, to newUserId: String?) async
}
```

### 4.2 Update Repositories
```swift
// Repositories/PieceRepository.swift
extension PieceRepository {
    func fetchAll(for userId: String?) throws -> [Piece]
    func search(query: String, for userId: String?) throws -> [Piece]
}

// Repositories/PracticeSessionRepository.swift  
extension PracticeSessionRepository {
    func fetchSessions(for piece: Piece, userId: String?) throws -> [PracticeSession]
}
```

### 4.3 Update ViewModels
All ViewModels need to respect user context:
- RepertoireListViewModel
- PracticeViewModel
- AddEditPieceViewModel
- ProfileViewModel

## Phase 5: Integration and Polish (Day 5)

### 5.1 App Startup Flow
```swift
// HaumanaApp.swift
@main
struct HaumanaApp: App {
    @State private var authViewModel = AuthenticationViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authViewModel)
                .task {
                    await authViewModel.restoreAuthentication()
                }
        }
    }
}
```

### 5.2 Error Handling
- Network errors during sign-in
- Google Sign-In cancellation
- Account already exists scenarios
- Migration failures

### 5.3 Loading States
- Sign-in progress indicator
- Migration progress for existing data
- Skeleton screens during authentication

## Phase 6: Testing and TestFlight (Days 6-7)

### 6.1 Unit Tests
```swift
// AuthenticationServiceTests
- testSuccessfulSignIn()
- testSignInCancellation()
- testSignOut()
- testUserPersistence()

// UserMigrationServiceTests
- testLocalDataMigration()
- testUserDataFiltering()
- testAccountSwitching()
```

### 6.2 UI Tests
```swift
// AuthenticationUITests
- testSignInFlow()
- testSignOutWithConfirmation()
- testProfileDisplaysUserInfo()
- testDataVisibilityAfterSignIn()
```

### 6.3 TestFlight Deployment
1. Update version to 0.4.0-beta.1
2. Archive and upload to App Store Connect
3. Configure external testing group
4. Add beta testing notes
5. Submit for beta review

### 6.4 Beta Testing Checklist
- [ ] Sign in with multiple Google accounts
- [ ] Verify data separation between accounts
- [ ] Test offline functionality
- [ ] Confirm migration of existing data
- [ ] Validate sign-out clears user data
- [ ] Check privacy policy and terms links

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
2. Show clear loading indicators
3. Provide helpful error messages
4. Maintain app usability when signed out
5. Respect system dark mode

## Success Criteria

- [ ] Google Sign-In works reliably
- [ ] User data properly scoped
- [ ] Existing data migrated successfully
- [ ] Profile tab shows correct state
- [ ] No data leaks between users
- [ ] TestFlight build approved
- [ ] Beta testers can authenticate

## Risk Mitigation

1. **Data Loss**: Implement backup before migration
2. **Auth Failures**: Robust offline fallback
3. **Privacy Concerns**: Minimal data collection
4. **Migration Bugs**: Extensive testing, reversible process
5. **Beta Issues**: Quick iteration based on feedback

## Timeline Summary

- **Day 1**: Project setup and configuration
- **Day 2**: Core authentication implementation  
- **Day 3**: Profile tab UI updates
- **Day 4**: Data migration and scoping
- **Day 5**: Integration and polish
- **Days 6-7**: Testing and TestFlight deployment

Total: 7 days (1 week) as specified in roadmap