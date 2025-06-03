//
//  SwiftDataIntegrationTests.swift
//  haumanaTests
//
//  Created on 6/2/2025.
//

import Testing
import Foundation
import SwiftData
@testable import haumana

@MainActor
struct SwiftDataIntegrationTests {
    
    private func createTestContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Piece.self, configurations: config)
    }
    
    @Test func testPiecePersistence() async throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        // Create a piece
        let piece = Piece(
            title: "Test Oli",
            category: .oli,
            lyrics: "Test lyrics for oli",
            language: "haw",
            author: "Test Author"
        )
        
        context.insert(piece)
        try context.save()
        
        // Fetch the piece
        let descriptor = FetchDescriptor<Piece>()
        let pieces = try context.fetch(descriptor)
        
        #expect(pieces.count == 1)
        #expect(pieces.first?.title == "Test Oli")
        #expect(pieces.first?.author == "Test Author")
    }
    
    @Test func testMultiplePieces() async throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        // Create multiple pieces
        let titles = ["Oli 1", "Mele 1", "Oli 2", "Mele 2"]
        for (index, title) in titles.enumerated() {
            let piece = Piece(
                title: title,
                category: index % 2 == 0 ? .oli : .mele,
                lyrics: "Lyrics for \(title)"
            )
            context.insert(piece)
        }
        
        try context.save()
        
        // Fetch all pieces
        let descriptor = FetchDescriptor<Piece>(sortBy: [SortDescriptor(\.title)])
        let pieces = try context.fetch(descriptor)
        
        #expect(pieces.count == 4)
        #expect(pieces.map { $0.title } == ["Mele 1", "Mele 2", "Oli 1", "Oli 2"])
    }
    
    @Test func testPieceUpdate() async throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        // Create and save a piece
        let piece = Piece(
            title: "Original Title",
            category: .oli,
            lyrics: "Original lyrics"
        )
        context.insert(piece)
        try context.save()
        
        // Update the piece
        piece.title = "Updated Title"
        piece.lyrics = "Updated lyrics"
        piece.updatedAt = Date()
        piece.isFavorite = true
        
        try context.save()
        
        // Fetch and verify
        let descriptor = FetchDescriptor<Piece>()
        let pieces = try context.fetch(descriptor)
        
        #expect(pieces.count == 1)
        #expect(pieces.first?.title == "Updated Title")
        #expect(pieces.first?.lyrics == "Updated lyrics")
        #expect(pieces.first?.isFavorite == true)
    }
    
    @Test func testPieceDeletion() async throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        // Create pieces
        let piece1 = Piece(title: "Keep Me", category: .oli, lyrics: "Keep")
        let piece2 = Piece(title: "Delete Me", category: .mele, lyrics: "Delete")
        
        context.insert(piece1)
        context.insert(piece2)
        try context.save()
        
        // Delete one piece
        context.delete(piece2)
        try context.save()
        
        // Verify
        let descriptor = FetchDescriptor<Piece>()
        let pieces = try context.fetch(descriptor)
        
        #expect(pieces.count == 1)
        #expect(pieces.first?.title == "Keep Me")
    }
    
    @Test func testOptionalFields() async throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        // Create piece with all optional fields
        let fullPiece = Piece(
            title: "Full Piece",
            category: .oli,
            lyrics: "Full lyrics",
            englishTranslation: "English translation",
            author: "Author Name",
            sourceUrl: "https://example.com",
            notes: "Some notes"
        )
        
        // Create piece with no optional fields
        let minimalPiece = Piece(
            title: "Minimal Piece",
            category: .mele,
            lyrics: "Minimal lyrics"
        )
        
        context.insert(fullPiece)
        context.insert(minimalPiece)
        try context.save()
        
        // Fetch and verify
        let descriptor = FetchDescriptor<Piece>(sortBy: [SortDescriptor(\.title)])
        let pieces = try context.fetch(descriptor)
        
        #expect(pieces.count == 2)
        
        let full = pieces.first { $0.title == "Full Piece" }
        #expect(full?.englishTranslation == "English translation")
        #expect(full?.author == "Author Name")
        #expect(full?.sourceUrl == "https://example.com")
        #expect(full?.notes == "Some notes")
        
        let minimal = pieces.first { $0.title == "Minimal Piece" }
        #expect(minimal?.englishTranslation == nil)
        #expect(minimal?.author == nil)
        #expect(minimal?.sourceUrl == nil)
        #expect(minimal?.notes == nil)
    }
}