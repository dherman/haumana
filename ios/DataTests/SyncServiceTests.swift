//
//  SyncServiceTests.swift
//  DataTests
//
//  Created on 6/18/2025.
//

import XCTest
import SwiftData
@testable import haumana

@MainActor
final class SyncServiceTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var authService: MockAuthenticationService!
    var syncService: SyncService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container
        let schema = Schema([Piece.self, PracticeSession.self, User.self, SyncQueueItem.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)
        
        // Create mock auth service
        authService = MockAuthenticationService(modelContext: modelContext)
        
        // Create sync service
        syncService = SyncService(modelContext: modelContext, authService: authService)
    }
    
    override func tearDown() async throws {
        syncService = nil
        authService = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Sync Status Tests
    
    func testInitialSyncStatus() {
        XCTAssertEqual(syncService.syncStatus, .synced)
        XCTAssertNil(syncService.lastSyncedAt)
        XCTAssertEqual(syncService.pendingChanges, 0)
    }
    
    func testMarkPendingChanges() {
        syncService.markPendingChanges()
        XCTAssertEqual(syncService.pendingChanges, 1)
        XCTAssertEqual(syncService.syncStatus, .pendingChanges)
        
        syncService.markPendingChanges()
        XCTAssertEqual(syncService.pendingChanges, 2)
    }
    
    // MARK: - Authentication State Tests
    
    func testSyncRequiresAuthentication() async {
        // Ensure user is not signed in
        authService.currentUser = nil
        authService.isSignedIn = false
        
        await syncService.syncNow()
        
        // Sync should not proceed without authentication
        XCTAssertEqual(syncService.syncStatus, .synced)
        XCTAssertNil(syncService.lastSyncedAt)
    }
    
    func testSyncWithAuthentication() async throws {
        // Sign in user
        let user = User(id: "test-user", email: "test@example.com", displayName: "Test User", photoUrl: nil)
        modelContext.insert(user)
        try modelContext.save()
        
        authService.currentUser = user
        authService.isSignedIn = true
        authService.mockIdToken = "mock-id-token"
        
        // Create test data
        let piece = Piece(
            title: "Test Oli",
            category: .oli,
            lyrics: "Test lyrics",
            language: "haw"
        )
        piece.userId = user.id
        piece.locallyModified = true
        modelContext.insert(piece)
        try modelContext.save()
        
        // Mock successful sync
        authService.mockSyncSuccess = true
        
        await syncService.syncNow()
        
        // Verify sync was attempted
        XCTAssertTrue(authService.getCurrentIdTokenCalled)
    }
    
    // MARK: - Error Handling Tests
    
    func testSyncErrorHandling() async throws {
        // Sign in user
        let user = User(id: "test-user", email: "test@example.com", displayName: "Test User", photoUrl: nil)
        modelContext.insert(user)
        try modelContext.save()
        
        authService.currentUser = user
        authService.isSignedIn = true
        authService.mockIdToken = nil // Will cause sync to fail
        
        await syncService.syncNow()
        
        // Verify error status
        if case .error = syncService.syncStatus {
            // Success - error was properly handled
        } else {
            XCTFail("Expected error status")
        }
    }
    
    // MARK: - Concurrent Sync Tests
    
    func testConcurrentSyncPrevention() async {
        authService.currentUser = User(id: "test-user", email: "test@example.com", displayName: "Test User", photoUrl: nil)
        authService.isSignedIn = true
        authService.mockIdToken = "mock-id-token"
        
        // Start multiple syncs
        Task {
            await syncService.syncNow()
        }
        
        // Second sync should be skipped
        await syncService.syncNow()
        
        // Only one sync should have been executed
        XCTAssertEqual(authService.getCurrentIdTokenCallCount, 1)
    }
    
    // MARK: - Offline Queue Tests
    
    func testOfflineQueue() async throws {
        // Create offline queue manager
        let offlineQueue = OfflineQueueManager(modelContext: modelContext)
        
        // Sign in user
        let user = User(id: "test-user", email: "test@example.com", displayName: "Test User", photoUrl: nil)
        modelContext.insert(user)
        try modelContext.save()
        
        authService.currentUser = user
        authService.isSignedIn = true
        
        // Enqueue some items while offline
        offlineQueue.enqueue(entityType: "piece", entityId: UUID().uuidString, operation: "create", userId: user.id)
        offlineQueue.enqueue(entityType: "piece", entityId: UUID().uuidString, operation: "update", userId: user.id)
        offlineQueue.enqueue(entityType: "session", entityId: UUID().uuidString, operation: "create", userId: user.id)
        
        // Verify items are queued
        let queueCount = try offlineQueue.getQueueCount()
        XCTAssertEqual(queueCount, 3)
        
        // Process queue (will fail since processItem throws)
        do {
            try await offlineQueue.processQueue()
        } catch {
            // Expected - processItem is not implemented
        }
        
        // Verify items are still in queue with increased retry count
        let descriptor = FetchDescriptor<SyncQueueItem>()
        let items = try modelContext.fetch(descriptor)
        XCTAssertEqual(items.count, 3)
        XCTAssertTrue(items.allSatisfy { $0.retryCount == 1 })
    }
    
    // MARK: - Retry Logic Tests
    
    func testRetryLogic() async throws {
        let offlineQueue = OfflineQueueManager(modelContext: modelContext)
        
        // Create a queue item
        let item = SyncQueueItem(
            entityType: "piece",
            entityId: UUID().uuidString,
            operation: "update",
            userId: "test-user"
        )
        modelContext.insert(item)
        try modelContext.save()
        
        // Process queue multiple times to test retry
        for expectedRetryCount in 1...3 {
            do {
                try await offlineQueue.processQueue()
            } catch {
                // Expected failure
            }
            
            // Verify retry count increased
            let descriptor = FetchDescriptor<SyncQueueItem>()
            let items = try modelContext.fetch(descriptor)
            XCTAssertEqual(items.first?.retryCount, expectedRetryCount)
        }
        
        // After 3 retries, item should not be processed anymore
        let initialCount = try offlineQueue.getQueueCount()
        XCTAssertEqual(initialCount, 0) // Item has exceeded retry limit
        
        // Verify item still exists but won't be processed
        let allItems = try modelContext.fetch(FetchDescriptor<SyncQueueItem>())
        XCTAssertEqual(allItems.count, 1)
        XCTAssertEqual(allItems.first?.retryCount, 3)
    }
}

// MARK: - Mock Authentication Service

@MainActor
class MockAuthenticationService: AuthenticationServiceProtocol {
    var currentUser: User?
    var isSignedIn: Bool = false
    let modelContext: ModelContext
    
    // Mock configuration
    var mockIdToken: String?
    var mockSyncSuccess = true
    var getCurrentIdTokenCalled = false
    var getCurrentIdTokenCallCount = 0
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func checkAuthenticationStatus() {
        // No-op for tests
    }
    
    func signIn(presenting viewController: UIViewController) async throws {
        // No-op for tests
    }
    
    func signOut() async {
        currentUser = nil
        isSignedIn = false
    }
    
    func restorePreviousSignIn() async {
        // No-op for tests
    }
    
    func getCurrentIdToken() async throws -> String? {
        getCurrentIdTokenCalled = true
        getCurrentIdTokenCallCount += 1
        
        if let token = mockIdToken {
            return token
        } else {
            throw NSError(domain: "MockAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No mock token"])
        }
    }
}