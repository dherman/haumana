# Milestone 4: Google Authentication - Implementation Plan

## Overview

This implementation plan details the technical steps to add Google Sign-In authentication to Haumana, establishing user identity management and preparing for cloud synchronization in Milestone 5.

## Prerequisites

1. Apple Developer account with app identifier configured
2. Google Cloud Console project for OAuth 2.0
3. Privacy policy and terms of service documents prepared

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

## Phase 4: Sign-In Screen Implementation (Day 4)

### 4.1 Create Sign-In Screen
```swift
// Views/SignInView.swift
import SwiftUI
import GoogleSignIn

struct SignInView: View {
    @Environment(AuthenticationViewModel.self) private var authViewModel
    
    var body: some View {
        ZStack {
            // Full-screen red background (lehua color)
            Color(red: 0.8, green: 0.2, blue: 0.2)
                .ignoresSafeArea()
            
            // Centered sign-in button
            VStack {
                Button(action: { 
                    Task { await authViewModel.signIn() }
                }) {
                    // Google Sign-In button styling
                    HStack {
                        Image("google_logo")
                        Text("Sign in with Google")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(authViewModel.isLoading)
            }
            
            // Loading overlay
            if authViewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
    }
}
```

### 4.2 Update App Entry Point
```swift
// HaumanaApp.swift
@main
struct HaumanaApp: App {
    @State private var authService = AuthenticationService()
    @State private var showingSignIn = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isSignedIn {
                    MainTabView()
                        .environment(\.authService, authService)
                } else {
                    SignInView()
                        .environment(AuthenticationViewModel(authService: authService))
                }
            }
            .task {
                // Check for existing authentication
                await authService.restorePreviousSignIn()
            }
        }
    }
}
```

### 4.3 Smart Navigation After Sign-In
```swift
// AuthenticationViewModel.swift - Update signIn method
func signIn() async {
    guard !isLoading else { return }
    
    isLoading = true
    errorMessage = nil
    
    do {
        // ... existing sign-in logic ...
        try await authService.signIn(presenting: rootViewController)
        
        // After successful sign-in, check repertoire
        let pieceRepository = PieceRepository(modelContext: modelContext)
        let userPieces = try pieceRepository.fetchAll(userId: authService.currentUser?.id)
        
        // Navigate based on repertoire state
        if userPieces.isEmpty {
            // Will be handled by MainTabView to show Repertoire tab
            shouldNavigateToRepertoire = true
        }
    } catch {
        errorMessage = "Sign in failed: \(error.localizedDescription)"
    }
    
    isLoading = false
}
```

### 4.4 Update MainTabView
```swift
// Views/MainTabView.swift
struct MainTabView: View {
    @Environment(\.authService) private var authService
    @State private var selectedTab = 0
    @Query private var pieces: [Piece]
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PracticeTabView()
                .tabItem { 
                    Label("Practice", systemImage: "music.note") 
                }
                .tag(0)
            
            RepertoireListView()
                .tabItem { 
                    Label("Repertoire", systemImage: "music.note.list") 
                }
                .tag(1)
            
            // History and Profile tabs...
        }
        .onAppear {
            // If user just signed in and has no pieces, show Repertoire
            if pieces.filter({ $0.userId == authService.currentUser?.id }).isEmpty {
                selectedTab = 1
            }
        }
    }
}
```

## Phase 5: Simplify Authenticated Experience (Day 5)

### 5.1 Remove Signed-Out States from Views
All main app views can now assume the user is authenticated:

```swift
// Update PracticeTabView, RepertoireListView, HistoryTabView
// Remove any checks for authentication state
// Remove "sign in to sync" messages
// Always use authService.currentUser!.id for queries
```

### 5.2 Update Profile Tab Sign-Out Flow
```swift
// ProfileTabView.swift - Update sign-out handling
func confirmSignOut() {
    authService.signOut()
    // App will automatically show SignInView due to authService.isSignedIn change
}
```

### 5.3 Error Handling
- Network errors during sign-in (show on SignInView)
- Google Sign-In cancellation (remain on SignInView)
- Authentication token expiry (return to SignInView)

### 5.4 Polish Sign-In Screen
- Add app logo or title above button
- Ensure proper Google Sign-In button styling
- Test on different screen sizes
- Add subtle animation during loading

## Phase 6: Testing (Days 6-7)

### 6.1 Unit Tests
```swift
// AuthenticationServiceTests
- testSuccessfulSignIn()
- testSignInCancellation()
- testSignOut()
- testUserPersistence()
- testRestorePreviousSignIn()

// DataScopingTests
- testPiecesFilteredByUserId()
- testSessionsFilteredByUserId()
- testNewPieceAssignedToCurrentUser()
- testDataIsolationBetweenUsers()
```

### 6.2 UI Tests
```swift
// AuthenticationUITests
- testSplashToSignInFlow()
- testSignInFlow()
- testSignInWithEmptyRepertoire() // Should navigate to Repertoire tab
- testSignInWithExistingPieces() // Should navigate to Practice tab
- testSignOutFromProfile() // Should return to SignInView
- testSignInCancellation() // Should remain on SignInView
- testErrorMessageDisplay()

// AuthenticatedFlowTests  
- testAllTabsRequireAuthentication()
- testAddPieceAssignedToUser()
- testUserOnlySeesOwnPieces()
```

### 6.3 Manual Testing Checklist

#### Authentication Flow
- [x] App launches with splash screen animation
- [x] Splash screen transitions to Sign-In screen when not authenticated
- [x] Splash screen transitions to MainTabView when authenticated
- [x] Sign-In screen has red background (lehua color)
- [x] Google Sign-In button is properly styled and centered
- [x] Loading indicator shows during authentication
- [x] Error messages display correctly on sign-in failure

#### Navigation After Sign-In
- [x] First-time user (empty repertoire) lands on Repertoire tab
- [x] Returning user (has pieces) lands on Practice tab
- [x] Tab bar appears only after successful authentication

#### Data Scoping
- [x] User only sees their own pieces in Repertoire
- [x] Practice carousel only shows user's pieces
- [x] New pieces are assigned to current user
- [x] Sign out and sign in with different account shows different data

#### Sign-Out Flow  
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

- [ ] Sign-In screen displays with red background
- [ ] Google Sign-In works reliably
- [ ] User data properly scoped
- [ ] Smart navigation after sign-in based on repertoire
- [ ] Profile tab shows authenticated user info
- [ ] Sign-out returns to Sign-In screen
- [ ] No data leaks between users
- [ ] All features tested on physical device

## Risk Mitigation

1. **Data Isolation**: Ensure proper userId filtering in all queries
2. **Auth Failures**: Clear error messages and retry options
3. **Privacy Concerns**: Minimal data collection, only essential user info
4. **Navigation Bugs**: Thorough testing of all auth state transitions

## Timeline Summary

- **Day 1**: Project setup and configuration ✓
- **Day 2**: Core authentication implementation ✓
- **Day 3**: Profile tab UI updates ✓
- **Day 4**: Sign-In screen implementation
- **Day 5**: Simplify authenticated experience
- **Day 6**: Integration and navigation flow
- **Days 7-8**: Testing and final polish

Total: 8 days (slightly extended due to design changes)