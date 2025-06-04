//
//  PieceModelTests.swift
//  haumanaTests
//
//  Created on 6/2/2025.
//

import Testing
import Foundation
@testable import haumana

struct PieceModelTests {
    
    @Test func testPieceDefaults() {
        let piece = Piece(
            title: "Test Oli",
            category: .oli,
            lyrics: "Test lyrics"
        )
        
        #expect(piece.language == "haw")
        #expect(piece.englishTranslation == nil)
        #expect(piece.author == nil)
        #expect(piece.sourceUrl == nil)
        #expect(piece.notes == nil)
        #expect(piece.isFavorite == false)
        #expect(piece.includeInPractice == true)
        #expect(piece.lastPracticed == nil)
    }
    
    @Test func testCategoryEnum() {
        let oliPiece = Piece(title: "Oli", category: .oli, lyrics: "Oli lyrics")
        let melePiece = Piece(title: "Mele", category: .mele, lyrics: "Mele lyrics")
        
        #expect(oliPiece.categoryEnum == .oli)
        #expect(melePiece.categoryEnum == .mele)
        
        // Test display names
        #expect(PieceCategory.oli.displayName == "Oli")
        #expect(PieceCategory.mele.displayName == "Mele")
    }
    
    @Test func testDisplayLanguage() {
        let hawaiianPiece = Piece(title: "Hawaiian", category: .oli, lyrics: "Test", language: "haw")
        let englishPiece = Piece(title: "English", category: .mele, lyrics: "Test", language: "eng")
        let otherPiece = Piece(title: "Other", category: .oli, lyrics: "Test", language: "jpn")
        
        #expect(hawaiianPiece.displayLanguage == "ʻŌlelo Hawaiʻi")
        #expect(englishPiece.displayLanguage == "English")
        #expect(otherPiece.displayLanguage == "jpn")
    }
    
    @Test func testLyricsPreview() {
        let shortPiece = Piece(
            title: "Short",
            category: .oli,
            lyrics: "Line 1"
        )
        #expect(shortPiece.lyricsPreview == "Line 1")
        
        let multilinePiece = Piece(
            title: "Multiline",
            category: .mele,
            lyrics: "Line 1\nLine 2\nLine 3\nLine 4\nLine 5"
        )
        #expect(multilinePiece.lyricsPreview == "Line 1\nLine 2\nLine 3")
        
        let emptyLinesPiece = Piece(
            title: "Empty Lines",
            category: .oli,
            lyrics: "Line 1\n\nLine 2\n\n\nLine 3\nLine 4"
        )
        #expect(emptyLinesPiece.lyricsPreview == "Line 1\nLine 2\nLine 3")
    }
    
    @Test func testTimestamps() {
        let before = Date()
        let piece = Piece(title: "Test", category: .oli, lyrics: "Test")
        let after = Date()
        
        // Allow for small timing differences (1 second tolerance)
        #expect(piece.createdAt.timeIntervalSince(before) >= -1.0)
        #expect(piece.createdAt.timeIntervalSince(after) <= 1.0)
        #expect(piece.updatedAt.timeIntervalSince(before) >= -1.0)
        #expect(piece.updatedAt.timeIntervalSince(after) <= 1.0)
        
        // CreatedAt and UpdatedAt should be the same on initialization
        #expect(abs(piece.createdAt.timeIntervalSince(piece.updatedAt)) < 0.001)
    }
}