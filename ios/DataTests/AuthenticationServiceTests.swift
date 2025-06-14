import XCTest
import SwiftData
import UIKit
@testable import haumana

@MainActor
final class AuthenticationServiceTests: XCTestCase {
    private var modelContainer: ModelContainer!
    private var authService: AuthenticationService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container for testing
        let schema = Schema([User.self, Piece.self, PracticeSession.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        // Create auth service - init will skip Google Sign-In check in test environment
        authService = AuthenticationService(modelContext: modelContainer.mainContext)
    }
    
    override func tearDown() async throws {
        authService = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - User Management Tests
    
    func testInitialStateIsSignedOut() {
        XCTAssertNil(authService.currentUser)
        XCTAssertFalse(authService.isSignedIn)
    }
    
    func testSignOutClearsUserState() async throws {
        // Given: Create and sign in a user using the test mode
        let mockVC = UIViewController()
        try await authService.signIn(presenting: mockVC)
        
        // Verify signed in (in test mode, this creates a test user)
        XCTAssertNotNil(authService.currentUser)
        XCTAssertTrue(authService.isSignedIn)
        
        // When: Sign out
        authService.signOut()
        
        // Then: User state should be cleared
        XCTAssertNil(authService.currentUser)
        XCTAssertFalse(authService.isSignedIn)
    }
    
    func testUserPersistenceInDatabase() async throws {
        // Given: No user exists initially
        let descriptor = FetchDescriptor<User>()
        let initialUsers = try modelContainer.mainContext.fetch(descriptor)
        XCTAssertEqual(initialUsers.count, 0)
        
        // When: Sign in (test mode creates a mock user)
        let mockVC = UIViewController()
        try await authService.signIn(presenting: mockVC)
        
        // Then: User should be persisted in database
        let users = try modelContainer.mainContext.fetch(descriptor)
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users.first?.id, "test-user-123")
        XCTAssertEqual(users.first?.email, "test@example.com")
    }
    
    func testPreventDuplicateUsers() async throws {
        // Given: Sign in once
        let mockVC = UIViewController()
        try await authService.signIn(presenting: mockVC)
        
        // When: Sign in again with same user
        try await authService.signIn(presenting: mockVC)
        
        // Then: Still only one user should exist
        let descriptor = FetchDescriptor<User>()
        let users = try modelContainer.mainContext.fetch(descriptor)
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users.first?.id, "test-user-123")
    }
    
    func testModelContextIsAccessible() {
        XCTAssertNotNil(authService.modelContext)
        XCTAssertEqual(authService.modelContext, modelContainer.mainContext)
    }
    
    func testRestorePreviousSignInWithNoUser() async {
        // When: Restore previous sign-in with no existing user
        await authService.restorePreviousSignIn()
        
        // Then: Should remain signed out
        XCTAssertNil(authService.currentUser)
        XCTAssertFalse(authService.isSignedIn)
    }
}