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
}

@MainActor
final class PracticeSelectionService: PracticeSelectionServiceProtocol {
    private let pieceRepository: PieceRepositoryProtocol
    private let modelContext: ModelContext
    
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
}