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
    func getRecentSessions(limit: Int) throws -> [PracticeSession]
    func getSessionsForPiece(pieceId: UUID) throws -> [PracticeSession]
    func getTotalSessionCount() throws -> Int
    func getStreak() throws -> Int
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
}