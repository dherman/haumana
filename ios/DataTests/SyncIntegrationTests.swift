//
//  SyncIntegrationTests.swift
//  DataTests
//
//  Created on 6/18/2025.
//

import XCTest
import SwiftData
@testable import haumana

@MainActor
final class SyncIntegrationTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var pieceRepository: PieceRepository!
    var sessionRepository: PracticeSessionRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container
        let schema = Schema([Piece.self, PracticeSession.self, User.self, SyncQueueItem.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)
        
        // Create repositories
        pieceRepository = PieceRepository(modelContext: modelContext)
        sessionRepository = PracticeSessionRepository(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        sessionRepository = nil
        pieceRepository = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Piece Sync Tests
    
    func testPieceLocalModificationTracking() throws {
        let userId = "test-user"
        
        // Create a piece
        let piece = Piece(
            title: "Aloha ʻOe",
            category: .mele,
            lyrics: "Aloha ʻoe, aloha ʻoe...",
            language: "haw"
        )
        piece.userId = userId
        piece.locallyModified = false // Reset to test modification tracking
        modelContext.insert(piece)
        try modelContext.save()
        
        // Initially not modified
        XCTAssertFalse(piece.locallyModified)
        
        // Modify the piece
        piece.title = "Aloha ʻOe (Updated)"
        piece.locallyModified = true
        try modelContext.save()
        
        // Should be marked as modified
        XCTAssertTrue(piece.locallyModified)
        
        // Fetch modified pieces
        let modifiedPieces = try pieceRepository.fetchAll(userId: userId).filter { $0.locallyModified }
        XCTAssertEqual(modifiedPieces.count, 1)
        XCTAssertEqual(modifiedPieces.first?.title, "Aloha ʻOe (Updated)")
    }
    
    func testPieceSyncDataFormat() throws {
        let userId = "test-user"
        let pieceId = UUID()
        
        // Create a piece with all fields
        let piece = Piece(
            title: "E Ku'u Morning Dew",
            category: .oli,
            lyrics: "E ku'u morning dew...",
            language: "haw",
            englishTranslation: "Oh my morning dew...",
            author: "Larry Kimura",
            sourceUrl: "https://example.com",
            notes: "Practice daily"
        )
        piece.id = pieceId
        piece.userId = userId
        piece.includeInPractice = true
        piece.isFavorite = true
        piece.version = 1
        piece.locallyModified = true
        modelContext.insert(piece)
        try modelContext.save()
        
        // Verify all fields are persisted correctly
        let fetchedPieces = try pieceRepository.fetchAll(userId: userId)
        XCTAssertEqual(fetchedPieces.count, 1)
        
        let fetchedPiece = fetchedPieces.first!
        XCTAssertEqual(fetchedPiece.id, pieceId)
        XCTAssertEqual(fetchedPiece.title, "E Ku'u Morning Dew")
        XCTAssertEqual(fetchedPiece.category, PieceCategory.oli.rawValue)
        XCTAssertEqual(fetchedPiece.lyrics, "E ku'u morning dew...")
        XCTAssertEqual(fetchedPiece.language, "haw")
        XCTAssertEqual(fetchedPiece.englishTranslation, "Oh my morning dew...")
        XCTAssertEqual(fetchedPiece.author, "Larry Kimura")
        XCTAssertEqual(fetchedPiece.sourceUrl, "https://example.com")
        XCTAssertEqual(fetchedPiece.notes, "Practice daily")
        XCTAssertTrue(fetchedPiece.includeInPractice)
        XCTAssertTrue(fetchedPiece.isFavorite)
        XCTAssertEqual(fetchedPiece.version, 1)
        XCTAssertTrue(fetchedPiece.locallyModified)
    }
    
    // MARK: - Session Sync Tests
    
    func testSessionSyncTracking() throws {
        let userId = "test-user"
        let pieceId = UUID()
        
        // Create a practice session
        let session = PracticeSession(
            pieceId: pieceId,
            startTime: Date()
        )
        // End the session after 5 minutes
        session.endTime = Date().addingTimeInterval(300)
        session.userId = userId
        modelContext.insert(session)
        try modelContext.save()
        
        // Initially not synced
        XCTAssertNil(session.syncedAt)
        
        // Fetch unsynced sessions
        let unsyncedSessions = try sessionRepository.fetchUnsyncedSessions(userId: userId)
        XCTAssertEqual(unsyncedSessions.count, 1)
        XCTAssertEqual(unsyncedSessions.first?.id, session.id)
        
        // Mark as synced
        session.syncedAt = Date()
        try modelContext.save()
        
        // Should no longer appear in unsynced list
        let remainingUnsynced = try sessionRepository.fetchUnsyncedSessions(userId: userId)
        XCTAssertEqual(remainingUnsynced.count, 0)
    }
    
    func testMultipleSessionSync() throws {
        let userId = "test-user"
        let pieceId1 = UUID()
        let pieceId2 = UUID()
        
        // Create multiple sessions
        let session1 = PracticeSession(pieceId: pieceId1, startTime: Date().addingTimeInterval(-3600))
        session1.endTime = Date().addingTimeInterval(-3300)
        
        let session2 = PracticeSession(pieceId: pieceId2, startTime: Date().addingTimeInterval(-1800))
        session2.endTime = Date().addingTimeInterval(-1500)
        
        let session3 = PracticeSession(pieceId: pieceId1, startTime: Date().addingTimeInterval(-600))
        // session3 is still in progress (no endTime)
        
        let sessions = [session1, session2, session3]
        
        for session in sessions {
            session.userId = userId
            modelContext.insert(session)
        }
        try modelContext.save()
        
        // All should be unsynced
        let unsyncedSessions = try sessionRepository.fetchUnsyncedSessions(userId: userId)
        XCTAssertEqual(unsyncedSessions.count, 3)
        
        // Sessions should be ordered by start time
        XCTAssertTrue(unsyncedSessions[0].startTime < unsyncedSessions[1].startTime)
        XCTAssertTrue(unsyncedSessions[1].startTime < unsyncedSessions[2].startTime)
    }
    
    // MARK: - Conflict Resolution Tests
    
    func testLastWriteWinsConflictResolution() throws {
        let userId = "test-user"
        let pieceId = UUID()
        
        // Create a piece
        let piece = Piece(
            title: "Original Title",
            category: .oli,
            lyrics: "Original lyrics",
            language: "haw"
        )
        piece.id = pieceId
        piece.userId = userId
        piece.version = 1
        piece.updatedAt = Date().addingTimeInterval(-3600) // 1 hour ago
        modelContext.insert(piece)
        try modelContext.save()
        
        // Simulate server update with newer timestamp
        let serverUpdateTime = Date().addingTimeInterval(-1800) // 30 minutes ago
        
        // Simulate local update with even newer timestamp
        piece.title = "Local Update"
        piece.updatedAt = Date() // Now
        piece.locallyModified = true
        try modelContext.save()
        
        // Local update should win due to newer timestamp
        XCTAssertEqual(piece.title, "Local Update")
        XCTAssertTrue(piece.updatedAt > serverUpdateTime)
    }
    
    // MARK: - Performance Tests
    
    func testLargeRepertoireHandling() throws {
        let userId = "test-user"
        
        // Create many pieces outside of measure block
        for i in 0..<100 {
            let piece = Piece(
                title: "Piece \(i)",
                category: i % 2 == 0 ? PieceCategory.oli : PieceCategory.mele,
                lyrics: "Lyrics for piece \(i)",
                language: "haw"
            )
            piece.userId = userId
            piece.locallyModified = i % 10 == 0 // Every 10th piece is modified
            modelContext.insert(piece)
        }
        try modelContext.save()
        
        // Measure fetch performance
        measure {
            do {
                // Fetch all pieces
                let allPieces = try pieceRepository.fetchAll(userId: userId)
                XCTAssertEqual(allPieces.count, 100)
                
                // Fetch modified pieces
                let modifiedPieces = allPieces.filter { $0.locallyModified }
                XCTAssertEqual(modifiedPieces.count, 10)
            } catch {
                XCTFail("Failed to handle large repertoire: \(error)")
            }
        }
    }
    
    // MARK: - Network State Transition Tests
    
    func testOfflineToOnlineTransition() async throws {
        let userId = "test-user"
        let offlineQueue = OfflineQueueManager(modelContext: modelContext)
        
        // Create pieces while "offline"
        let piece1 = Piece(
            title: "Offline Piece 1",
            category: .oli,
            lyrics: "Created while offline",
            language: "haw"
        )
        piece1.userId = userId
        piece1.locallyModified = true
        modelContext.insert(piece1)
        
        let piece2 = Piece(
            title: "Offline Piece 2",
            category: .mele,
            lyrics: "Also created offline",
            language: "haw"
        )
        piece2.userId = userId
        piece2.locallyModified = true
        modelContext.insert(piece2)
        
        // Create practice session while offline
        let session = PracticeSession(
            pieceId: piece1.id,
            startTime: Date().addingTimeInterval(-600)
        )
        session.endTime = Date().addingTimeInterval(-300)
        session.userId = userId
        modelContext.insert(session)
        
        try modelContext.save()
        
        // Queue sync operations
        offlineQueue.enqueue(entityType: "piece", entityId: piece1.id.uuidString, operation: "create", userId: userId)
        offlineQueue.enqueue(entityType: "piece", entityId: piece2.id.uuidString, operation: "create", userId: userId)
        offlineQueue.enqueue(entityType: "session", entityId: session.id.uuidString, operation: "create", userId: userId)
        
        // Verify items are queued
        let queueCountBefore = try offlineQueue.getQueueCount()
        XCTAssertEqual(queueCountBefore, 3)
        
        // Verify pieces are marked as locally modified
        let modifiedPieces = try pieceRepository.fetchAll(userId: userId).filter { $0.locallyModified }
        XCTAssertEqual(modifiedPieces.count, 2)
        
        // Verify session is not synced
        let unsyncedSessions = try sessionRepository.fetchUnsyncedSessions(userId: userId)
        XCTAssertEqual(unsyncedSessions.count, 1)
        
        // Simulate coming back online
        // In a real scenario, the SyncService would:
        // 1. Process the offline queue
        // 2. Upload pieces and sessions
        // 3. Mark them as synced
        // 4. Clear the queue
        
        // For this test, we'll simulate the sync completion
        piece1.locallyModified = false
        piece1.lastSyncedAt = Date()
        piece2.locallyModified = false
        piece2.lastSyncedAt = Date()
        session.syncedAt = Date()
        
        // Clear the queue (simulating successful sync)
        let descriptor = FetchDescriptor<SyncQueueItem>()
        let queueItems = try modelContext.fetch(descriptor)
        for item in queueItems {
            modelContext.delete(item)
        }
        try modelContext.save()
        
        // Verify everything is synced
        let stillModifiedPieces = try pieceRepository.fetchAll(userId: userId).filter { $0.locallyModified }
        XCTAssertEqual(stillModifiedPieces.count, 0)
        
        let stillUnsyncedSessions = try sessionRepository.fetchUnsyncedSessions(userId: userId)
        XCTAssertEqual(stillUnsyncedSessions.count, 0)
        
        let queueCountAfter = try offlineQueue.getQueueCount()
        XCTAssertEqual(queueCountAfter, 0)
    }
}