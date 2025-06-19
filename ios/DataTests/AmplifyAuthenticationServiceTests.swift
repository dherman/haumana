import XCTest
import SwiftData
@testable import haumana

@MainActor
final class AmplifyAuthenticationServiceTests: XCTestCase {
    private var modelContainer: ModelContainer!
    private var authService: AmplifyAuthenticationService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container for testing
        let schema = Schema([User.self, Piece.self, PracticeSession.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        // Create auth service - init will skip Amplify configuration in test environment
        authService = AmplifyAuthenticationService(modelContext: modelContainer.mainContext)
    }
    
    override func tearDown() async throws {
        authService = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    func testInitialization() {
        // Test that service initializes correctly
        XCTAssertNotNil(authService)
        XCTAssertFalse(authService.isSignedIn)
        XCTAssertNil(authService.currentUser)
    }
    
    func testMockSignIn() async throws {
        // Test mock sign-in behavior in test environment
        let mockViewController = UIViewController()
        
        // This should use mock behavior since we're in test environment
        try await authService.signIn(presenting: mockViewController)
        
        // Verify mock user was created
        XCTAssertTrue(authService.isSignedIn)
        XCTAssertNotNil(authService.currentUser)
        XCTAssertEqual(authService.currentUser?.email, "test@example.com")
        XCTAssertEqual(authService.currentUser?.displayName, "Test User")
    }
    
    func testSignOut() async throws {
        // First sign in with mock
        let mockViewController = UIViewController()
        try await authService.signIn(presenting: mockViewController)
        
        // Then sign out
        authService.signOut()
        
        // Verify signed out state
        XCTAssertFalse(authService.isSignedIn)
        XCTAssertNil(authService.currentUser)
    }
}