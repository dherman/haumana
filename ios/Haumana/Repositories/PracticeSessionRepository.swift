//
//  PracticeSessionRepository.swift
//  haumana
//
//  Created on 6/3/2025.
//

import Foundation
import SwiftData

protocol PracticeSessionRepositoryProtocol {
    func save(_ session: PracticeSession) throws
    func save(_ session: PracticeSession) async throws
    func getRecentSessions(limit: Int) throws -> [PracticeSession]
    func getRecentSessions(limit: Int) async throws -> [PracticeSession]
    func getSessionsForPiece(pieceId: UUID) throws -> [PracticeSession]
    func getTotalSessionCount() throws -> Int
    func getTotalSessionCount() async throws -> Int
    func getStreak() throws -> Int
    func getStreak() async throws -> Int
    func getMostPracticedPiece() throws -> (pieceId: UUID, count: Int)?
    func getMostPracticedPiece() async throws -> (pieceId: UUID, count: Int)?
}

final class PracticeSessionRepository: PracticeSessionRepositoryProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func save(_ session: PracticeSession) throws {
        modelContext.insert(session)
        try modelContext.save()
    }
    
    func getRecentSessions(limit: Int = AppConstants.recentSessionsLimit) throws -> [PracticeSession] {
        let descriptor = FetchDescriptor<PracticeSession>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        let sessions = try modelContext.fetch(descriptor)
        return Array(sessions.prefix(limit))
    }
    
    func getSessionsForPiece(pieceId: UUID) throws -> [PracticeSession] {
        let descriptor = FetchDescriptor<PracticeSession>(
            predicate: #Predicate { session in
                session.pieceId == pieceId
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func getTotalSessionCount() throws -> Int {
        let descriptor = FetchDescriptor<PracticeSession>()
        return try modelContext.fetchCount(descriptor)
    }
    
    func getStreak() throws -> Int {
        let descriptor = FetchDescriptor<PracticeSession>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        let sessions = try modelContext.fetch(descriptor)
        
        guard !sessions.isEmpty else { return 0 }
        
        var streak = 0
        var currentDate = Date()
        let calendar = Calendar.current
        
        // Start from today and work backwards
        while true {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let hasPractice = sessions.contains { session in
                session.startTime >= dayStart && session.startTime < dayEnd
            }
            
            if hasPractice {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else if calendar.isDateInToday(currentDate) {
                // Today doesn't have practice yet, check yesterday
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                // Streak is broken
                break
            }
        }
        
        return streak
    }
    
    func getMostPracticedPiece() throws -> (pieceId: UUID, count: Int)? {
        let descriptor = FetchDescriptor<PracticeSession>()
        let sessions = try modelContext.fetch(descriptor)
        
        guard !sessions.isEmpty else { return nil }
        
        // Count sessions per piece
        var pieceCounts: [UUID: Int] = [:]
        for session in sessions {
            pieceCounts[session.pieceId, default: 0] += 1
        }
        
        // Find the most practiced piece
        guard let mostPracticed = pieceCounts.max(by: { $0.value < $1.value }) else {
            return nil
        }
        
        return (pieceId: mostPracticed.key, count: mostPracticed.value)
    }
}

// MARK: - Async versions
extension PracticeSessionRepository {
    func save(_ session: PracticeSession) async throws {
        try await MainActor.run {
            try save(session)
        }
    }
    
    func getRecentSessions(limit: Int = AppConstants.recentSessionsLimit) async throws -> [PracticeSession] {
        try await MainActor.run {
            try getRecentSessions(limit: limit)
        }
    }
    
    func getTotalSessionCount() async throws -> Int {
        try await MainActor.run {
            try getTotalSessionCount()
        }
    }
    
    func getStreak() async throws -> Int {
        try await MainActor.run {
            try getStreak()
        }
    }
    
    func getMostPracticedPiece() async throws -> (pieceId: UUID, count: Int)? {
        try await MainActor.run {
            try getMostPracticedPiece()
        }
    }
}