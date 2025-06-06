//
//  PracticeSelectionService.swift
//  haumana
//
//  Created on 6/3/2025.
//

import Foundation
import SwiftData

@MainActor
protocol PracticeSelectionServiceProtocol {
    func selectRandomPiece() throws -> Piece?
    func getNextPiece(excluding: [UUID]) throws -> Piece?
    func generateSuggestionQueue(count: Int) throws -> [Piece]
    func refreshSuggestionQueue(currentQueue: [Piece], count: Int) throws -> [Piece]
}

@MainActor
final class PracticeSelectionService: PracticeSelectionServiceProtocol {
    private let pieceRepository: PieceRepositoryProtocol
    private let modelContext: ModelContext
    private var recentlyShownIds: Set<UUID> = []
    
    init(pieceRepository: PieceRepositoryProtocol, modelContext: ModelContext) {
        self.pieceRepository = pieceRepository
        self.modelContext = modelContext
    }
    
    func selectRandomPiece() throws -> Piece? {
        return try getNextPiece(excluding: [])
    }
    
    func getNextPiece(excluding excludedIds: [UUID]) throws -> Piece? {
        // Get all pieces eligible for practice
        let allEligiblePieces = try pieceRepository.fetchPracticeEligible()
            .filter { !excludedIds.contains($0.id) }
        
        guard !allEligiblePieces.isEmpty else { return nil }
        
        // If only one piece available, return it
        if allEligiblePieces.count == 1 {
            return allEligiblePieces.first
        }
        
        // Calculate days since last practice for each piece
        let currentDate = Date()
        let calendar = Calendar.current
        
        // Categorize pieces into priority groups
        var priority1: [Piece] = [] // Favorites not practiced in 7+ days
        var priority2: [Piece] = [] // Non-favorites not practiced in 7+ days
        var priority3: [Piece] = [] // All other eligible pieces
        
        for piece in allEligiblePieces {
            let daysSinceLastPractice: Int
            
            if let lastPracticed = piece.lastPracticed {
                let components = calendar.dateComponents([.day], from: lastPracticed, to: currentDate)
                daysSinceLastPractice = components.day ?? 0
            } else {
                // Never practiced - treat as very old
                daysSinceLastPractice = Int.max
            }
            
            if daysSinceLastPractice >= AppConstants.practiceHistoryDaysThreshold {
                if piece.isFavorite {
                    priority1.append(piece)
                } else {
                    priority2.append(piece)
                }
            } else {
                priority3.append(piece)
            }
        }
        
        // Calculate total weight without copying arrays
        let totalWeight = (AppConstants.priority1Weight * priority1.count) +
                         (AppConstants.priority2Weight * priority2.count) +
                         (AppConstants.priority3Weight * priority3.count)
        
        guard totalWeight > 0 else { return nil }
        
        // Select random number in range [0, totalWeight)
        let randomValue = Int.random(in: 0..<totalWeight)
        
        // Determine which priority group and index
        let priority1Range = AppConstants.priority1Weight * priority1.count
        let priority2Range = AppConstants.priority2Weight * priority2.count
        
        if randomValue < priority1Range {
            // Selected from priority1
            let index = randomValue / AppConstants.priority1Weight
            return priority1[index]
        } else if randomValue < priority1Range + priority2Range {
            // Selected from priority2
            let adjustedValue = randomValue - priority1Range
            let index = adjustedValue / AppConstants.priority2Weight
            return priority2[index]
        } else {
            // Selected from priority3
            let adjustedValue = randomValue - priority1Range - priority2Range
            let index = adjustedValue / AppConstants.priority3Weight
            return priority3[index]
        }
    }
    
    func generateSuggestionQueue(count: Int) throws -> [Piece] {
        recentlyShownIds.removeAll()
        var suggestions: [Piece] = []
        
        // Get all eligible pieces
        let eligiblePieces = try pieceRepository.fetchPracticeEligible()
        guard !eligiblePieces.isEmpty else { return [] }
        
        // If we have fewer pieces than requested, return all of them
        if eligiblePieces.count <= count {
            return eligiblePieces.shuffled()
        }
        
        // Generate suggestions ensuring variety
        for _ in 0..<count {
            if let piece = try getNextPiece(excluding: Array(recentlyShownIds)) {
                suggestions.append(piece)
                recentlyShownIds.insert(piece.id)
            } else {
                // If we can't get more unique pieces, stop
                break
            }
        }
        
        return suggestions
    }
    
    func refreshSuggestionQueue(currentQueue: [Piece], count: Int) throws -> [Piece] {
        // Keep track of what's already in the queue
        for piece in currentQueue {
            recentlyShownIds.insert(piece.id)
        }
        
        // If recently shown set gets too large (>50% of eligible pieces), reset it
        let eligibleCount = try pieceRepository.fetchPracticeEligible().count
        if recentlyShownIds.count > eligibleCount / 2 {
            recentlyShownIds.removeAll()
            // Re-add current queue items
            for piece in currentQueue {
                recentlyShownIds.insert(piece.id)
            }
        }
        
        var newQueue = currentQueue
        
        // Add new suggestions to reach the desired count
        while newQueue.count < count {
            if let piece = try getNextPiece(excluding: Array(recentlyShownIds)) {
                newQueue.append(piece)
                recentlyShownIds.insert(piece.id)
            } else {
                // Can't add more unique pieces
                break
            }
        }
        
        return newQueue
    }
}