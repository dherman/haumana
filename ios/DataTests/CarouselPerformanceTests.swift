//
//  CarouselPerformanceTests.swift
//  haumanaTests
//
//  Created on 6/6/2025.
//

import Testing
import Foundation
import SwiftData
@testable import haumana

@MainActor
struct CarouselPerformanceTests {
    
    private func createTestContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Piece.self, PracticeSession.self, configurations: config)
    }
    
    @Test func testPracticeSelectionWithManyPieces() async throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        // Create 1000 pieces
        for i in 1...1000 {
            let piece = Piece(
                title: "Test Piece \(i)",
                category: i % 2 == 0 ? .oli : .mele,
                lyrics: "Test lyrics for piece \(i)\nWith multiple lines\nTo simulate real content",
                language: i % 3 == 0 ? "haw" : "eng",
                author: "Test Author \(i % 10)"
            )
            piece.includeInPractice = true
            piece.isFavorite = i % 5 == 0
            
            // Simulate some pieces being practiced recently
            if i % 7 == 0 {
                piece.lastPracticed = Date().addingTimeInterval(-Double(i) * 3600) // Hours ago
            }
            
            context.insert(piece)
        }
        
        try context.save()
        
        // Test practice selection service performance
        let pieceRepository = PieceRepository(modelContext: context)
        let service = PracticeSelectionService(pieceRepository: pieceRepository, modelContext: context)
        
        // Measure selection queue generation
        let startTime = Date()
        let queue = try service.generateSuggestionQueue(count: 10)
        let endTime = Date()
        
        let duration = endTime.timeIntervalSince(startTime)
        
        // Performance assertions
        #expect(duration < 0.5, "Queue generation should complete in under 500ms with 1000 pieces")
        #expect(queue.count <= 10, "Queue should respect the limit")
        #expect(queue.count > 0, "Queue should have some pieces")
        
        // Test multiple queue generations (simulating carousel refresh)
        var totalDuration: TimeInterval = 0
        for _ in 1...10 {
            let start = Date()
            _ = try service.generateSuggestionQueue(count: 10)
            totalDuration += Date().timeIntervalSince(start)
        }
        
        let averageDuration = totalDuration / 10
        #expect(averageDuration < 0.1, "Average queue generation should be under 100ms")
    }
    
    @Test func testCarouselMemoryUsage() async throws {
        let container = try createTestContainer()
        let context = container.mainContext
        let viewModel = PracticeViewModel(modelContext: context)
        
        // Create 100 pieces with larger content
        for i in 1...100 {
            let piece = Piece(
                title: "Memory Test Piece \(i)",
                category: .oli,
                lyrics: String(repeating: "Long lyrics line \(i)\n", count: 100), // Simulate long content
                language: "haw"
            )
            piece.includeInPractice = true
            piece.englishTranslation = String(repeating: "Long translation line \(i)\n", count: 100)
            
            context.insert(piece)
        }
        
        try context.save()
        
        // Load statistics and queue
        await viewModel.loadStatistics()
        
        // Check that we're not loading all pieces into memory
        #expect(viewModel.suggestionQueue.count <= 10, "Should only load limited queue")
        
        // Simulate carousel navigation
        for _ in 1...20 {
            viewModel.currentCarouselIndex = (viewModel.currentCarouselIndex + 1) % viewModel.suggestionQueue.count
        }
        
        // Memory should remain stable (can't directly test but structure should support it)
        #expect(viewModel.suggestionQueue.count <= 10, "Queue size should remain limited")
    }
    
    @Test func testEdgeCaseNoEligiblePieces() async throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        // Create pieces but none eligible for practice
        for i in 1...5 {
            let piece = Piece(
                title: "Ineligible Piece \(i)",
                category: .oli,
                lyrics: "Test lyrics",
                language: "haw"
            )
            piece.includeInPractice = false // Not eligible
            context.insert(piece)
        }
        
        try context.save()
        
        let pieceRepository = PieceRepository(modelContext: context)
        let service = PracticeSelectionService(pieceRepository: pieceRepository, modelContext: context)
        let queue = try service.generateSuggestionQueue(count: 10)
        
        #expect(queue.isEmpty, "Queue should be empty when no pieces are eligible")
    }
    
    @Test func testEdgeCaseSinglePiece() async throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        // Create only one eligible piece
        let piece = Piece(
            title: "Single Piece",
            category: .mele,
            lyrics: "Only piece lyrics",
            language: "eng"
        )
        piece.includeInPractice = true
        context.insert(piece)
        
        try context.save()
        
        let pieceRepository = PieceRepository(modelContext: context)
        let service = PracticeSelectionService(pieceRepository: pieceRepository, modelContext: context)
        let queue = try service.generateSuggestionQueue(count: 10)
        
        #expect(queue.count == 1, "Queue should contain the single eligible piece")
        #expect(queue.first?.title == "Single Piece", "Queue should contain the correct piece")
    }
}