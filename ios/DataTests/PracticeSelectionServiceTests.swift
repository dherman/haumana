//
//  PracticeSelectionServiceTests.swift
//  haumanaTests
//
//  Created on 6/3/2025.
//

import Testing
import Foundation
import SwiftData
@testable import haumana

@MainActor
struct PracticeSelectionServiceTests {
    
    @Test func testWeightedSelection() async throws {
        // Create in-memory model container
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Piece.self, PracticeSession.self, configurations: config)
        let context = container.mainContext
        
        let repository = PieceRepository(modelContext: context)
        let service = PracticeSelectionService(pieceRepository: repository, modelContext: context)
        
        // Create test pieces
        let oldFavorite = Piece(title: "Old Favorite", category: .oli, lyrics: "Test")
        oldFavorite.isFavorite = true
        oldFavorite.includeInPractice = true
        oldFavorite.lastPracticed = Date().addingTimeInterval(-8 * 24 * 60 * 60) // 8 days ago
        
        let oldNonFavorite = Piece(title: "Old Non-Favorite", category: .mele, lyrics: "Test")
        oldNonFavorite.isFavorite = false
        oldNonFavorite.includeInPractice = true
        oldNonFavorite.lastPracticed = Date().addingTimeInterval(-8 * 24 * 60 * 60) // 8 days ago
        
        let recentPiece = Piece(title: "Recent", category: .oli, lyrics: "Test")
        recentPiece.isFavorite = false
        recentPiece.includeInPractice = true
        recentPiece.lastPracticed = Date().addingTimeInterval(-1 * 24 * 60 * 60) // 1 day ago
        
        // Add pieces to repository
        try await repository.add(oldFavorite)
        try await repository.add(oldNonFavorite)
        try await repository.add(recentPiece)
        
        // Test selection multiple times to verify weighted distribution
        var priority1Count = 0
        var priority2Count = 0
        var priority3Count = 0
        
        let iterations = 100
        for _ in 0..<iterations {
            if let selected = try service.selectRandomPiece() {
                if selected.id == oldFavorite.id {
                    priority1Count += 1
                } else if selected.id == oldNonFavorite.id {
                    priority2Count += 1
                } else if selected.id == recentPiece.id {
                    priority3Count += 1
                }
            }
        }
        
        // With weights 3:2:1, we expect roughly:
        // Priority 1: 50% (3/6)
        // Priority 2: 33% (2/6)  
        // Priority 3: 17% (1/6)
        
        // Just verify Priority 1 is selected more often than Priority 3
        #expect(priority1Count > priority3Count, "Priority 1 should be selected more often than Priority 3")
        
        // And that all priorities can be selected
        #expect(priority1Count > 0, "Priority 1 should be selected sometimes")
        #expect(priority2Count > 0, "Priority 2 should be selected sometimes")
        #expect(priority3Count > 0, "Priority 3 should be selected sometimes")
    }
    
    @Test func testExcludesPieces() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Piece.self, PracticeSession.self, configurations: config)
        let context = container.mainContext
        
        let repository = PieceRepository(modelContext: context)
        let service = PracticeSelectionService(pieceRepository: repository, modelContext: context)
        
        // Create test pieces
        let piece1 = Piece(title: "Piece 1", category: .oli, lyrics: "Test")
        piece1.includeInPractice = true
        
        let piece2 = Piece(title: "Piece 2", category: .mele, lyrics: "Test")
        piece2.includeInPractice = true
        
        try await repository.add(piece1)
        try await repository.add(piece2)
        
        // Exclude piece1
        let selected = try service.getNextPiece(excluding: [piece1.id])
        
        #expect(selected?.id == piece2.id, "Should not select excluded piece")
    }
    
    @Test func testReturnsNilWhenNoPiecesAvailable() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Piece.self, PracticeSession.self, configurations: config)
        let context = container.mainContext
        
        let repository = PieceRepository(modelContext: context)
        let service = PracticeSelectionService(pieceRepository: repository, modelContext: context)
        
        // Create piece but don't include in practice
        let piece = Piece(title: "Test", category: .oli, lyrics: "Test")
        piece.includeInPractice = false
        try await repository.add(piece)
        
        let selected = try service.selectRandomPiece()
        
        #expect(selected == nil, "Should return nil when no pieces available for practice")
    }
    
    @Test func testHandlesSinglePiece() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Piece.self, PracticeSession.self, configurations: config)
        let context = container.mainContext
        
        let repository = PieceRepository(modelContext: context)
        let service = PracticeSelectionService(pieceRepository: repository, modelContext: context)
        
        let piece = Piece(title: "Only Piece", category: .oli, lyrics: "Test")
        piece.includeInPractice = true
        try await repository.add(piece)
        
        let selected = try service.selectRandomPiece()
        
        #expect(selected?.id == piece.id, "Should return the only available piece")
    }
}