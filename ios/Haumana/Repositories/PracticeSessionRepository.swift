//
//  PracticeSessionRepository.swift
//  haumana
//
//  Created on 6/3/2025.
//

import Foundation
import SwiftData

protocol PracticeSessionRepositoryProtocol {
    func save(_ session: PracticeSession, userId: String?) throws
    @MainActor func save(_ session: PracticeSession, userId: String?) async throws
    func getRecentSessions(limit: Int, userId: String?) throws -> [PracticeSession]
    @MainActor func getRecentSessions(limit: Int, userId: String?) async throws -> [PracticeSession]
    func getSessionsForPiece(pieceId: UUID, userId: String?) throws -> [PracticeSession]
    func getTotalSessionCount(userId: String?) throws -> Int
    @MainActor func getTotalSessionCount(userId: String?) async throws -> Int
    func getStreak(userId: String?) throws -> Int
    @MainActor func getStreak(userId: String?) async throws -> Int
    func getMostPracticedPiece(userId: String?) throws -> (pieceId: UUID, count: Int)?
    @MainActor func getMostPracticedPiece(userId: String?) async throws -> (pieceId: UUID, count: Int)?
}

final class PracticeSessionRepository: PracticeSessionRepositoryProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func save(_ session: PracticeSession, userId: String? = nil) throws {
        session.userId = userId
        modelContext.insert(session)
        try modelContext.save()
        
        // Notify sync service
        NotificationCenter.default.post(name: NSNotification.Name("LocalDataChanged"), object: nil)
    }
    
    func getRecentSessions(limit: Int = AppConstants.recentSessionsLimit, userId: String? = nil) throws -> [PracticeSession] {
        let descriptor: FetchDescriptor<PracticeSession>
        if let userId = userId {
            descriptor = FetchDescriptor<PracticeSession>(
                predicate: #Predicate { session in
                    session.userId == userId
                },
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<PracticeSession>(
                predicate: #Predicate { session in
                    session.userId == nil
                },
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
        }
        let sessions = try modelContext.fetch(descriptor)
        return Array(sessions.prefix(limit))
    }
    
    func getSessionsForPiece(pieceId: UUID, userId: String? = nil) throws -> [PracticeSession] {
        let descriptor: FetchDescriptor<PracticeSession>
        if let userId = userId {
            descriptor = FetchDescriptor<PracticeSession>(
                predicate: #Predicate { session in
                    session.pieceId == pieceId && session.userId == userId
                },
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<PracticeSession>(
                predicate: #Predicate { session in
                    session.pieceId == pieceId && session.userId == nil
                },
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
        }
        return try modelContext.fetch(descriptor)
    }
    
    func getTotalSessionCount(userId: String? = nil) throws -> Int {
        let descriptor: FetchDescriptor<PracticeSession>
        if let userId = userId {
            descriptor = FetchDescriptor<PracticeSession>(
                predicate: #Predicate { session in
                    session.userId == userId
                }
            )
        } else {
            descriptor = FetchDescriptor<PracticeSession>(
                predicate: #Predicate { session in
                    session.userId == nil
                }
            )
        }
        return try modelContext.fetchCount(descriptor)
    }
    
    func getStreak(userId: String? = nil) throws -> Int {
        let descriptor: FetchDescriptor<PracticeSession>
        if let userId = userId {
            descriptor = FetchDescriptor<PracticeSession>(
                predicate: #Predicate { session in
                    session.userId == userId
                },
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<PracticeSession>(
                predicate: #Predicate { session in
                    session.userId == nil
                },
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
        }
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
    
    func getMostPracticedPiece(userId: String? = nil) throws -> (pieceId: UUID, count: Int)? {
        let descriptor: FetchDescriptor<PracticeSession>
        if let userId = userId {
            descriptor = FetchDescriptor<PracticeSession>(
                predicate: #Predicate { session in
                    session.userId == userId
                }
            )
        } else {
            descriptor = FetchDescriptor<PracticeSession>(
                predicate: #Predicate { session in
                    session.userId == nil
                }
            )
        }
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
    
    func fetchUnsyncedSessions(userId: String? = nil) throws -> [PracticeSession] {
        let descriptor: FetchDescriptor<PracticeSession>
        if let userId = userId {
            descriptor = FetchDescriptor<PracticeSession>(
                predicate: #Predicate { session in
                    session.userId == userId && session.syncedAt == nil
                },
                sortBy: [SortDescriptor(\.startTime)]
            )
        } else {
            descriptor = FetchDescriptor<PracticeSession>(
                predicate: #Predicate { session in
                    session.userId == nil && session.syncedAt == nil
                },
                sortBy: [SortDescriptor(\.startTime)]
            )
        }
        
        return try modelContext.fetch(descriptor)
    }
}

// MARK: - Async versions
extension PracticeSessionRepository {
    @MainActor
    func save(_ session: PracticeSession, userId: String? = nil) async throws {
        session.userId = userId
        modelContext.insert(session)
        try modelContext.save()
    }
    
    @MainActor
    func getRecentSessions(limit: Int = AppConstants.recentSessionsLimit, userId: String? = nil) async throws -> [PracticeSession] {
        let descriptor: FetchDescriptor<PracticeSession>
        if let userId = userId {
            descriptor = FetchDescriptor<PracticeSession>(
                predicate: #Predicate { session in
                    session.userId == userId
                },
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<PracticeSession>(
                predicate: #Predicate { session in
                    session.userId == nil
                },
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
        }
        let sessions = try modelContext.fetch(descriptor)
        return Array(sessions.prefix(limit))
    }
    
    @MainActor
    func getTotalSessionCount(userId: String? = nil) async throws -> Int {
        let descriptor: FetchDescriptor<PracticeSession>
        if let userId = userId {
            descriptor = FetchDescriptor<PracticeSession>(
                predicate: #Predicate { session in
                    session.userId == userId
                }
            )
        } else {
            descriptor = FetchDescriptor<PracticeSession>(
                predicate: #Predicate { session in
                    session.userId == nil
                }
            )
        }
        return try modelContext.fetchCount(descriptor)
    }
    
    @MainActor
    func getStreak(userId: String? = nil) async throws -> Int {
        let descriptor: FetchDescriptor<PracticeSession>
        if let userId = userId {
            descriptor = FetchDescriptor<PracticeSession>(
                predicate: #Predicate { session in
                    session.userId == userId
                },
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<PracticeSession>(
                predicate: #Predicate { session in
                    session.userId == nil
                },
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
        }
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
    
    @MainActor
    func getMostPracticedPiece(userId: String? = nil) async throws -> (pieceId: UUID, count: Int)? {
        let descriptor: FetchDescriptor<PracticeSession>
        if let userId = userId {
            descriptor = FetchDescriptor<PracticeSession>(
                predicate: #Predicate { session in
                    session.userId == userId
                }
            )
        } else {
            descriptor = FetchDescriptor<PracticeSession>(
                predicate: #Predicate { session in
                    session.userId == nil
                }
            )
        }
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