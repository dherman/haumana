//
//  ProfileViewModel.swift
//  haumana
//
//  Created on 6/4/2025.
//

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    private let pieceRepository: PieceRepositoryProtocol
    private let sessionRepository: PracticeSessionRepositoryProtocol
    private let modelContext: ModelContext
    
    // User info (placeholder for now)
    var userName: String = "Haumana User"
    var userEmail: String = "user@example.com"
    
    // Practice statistics
    var currentStreak: Int = 0
    var totalSessions: Int = 0
    var mostPracticedPiece: Piece?
    var mostPracticedCount: Int = 0
    
    // Recent practice history
    var recentSessions: [SessionWithPiece] = []
    
    // Loading state
    var isLoading = false
    var errorMessage: String?
    
    // App info
    let appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.pieceRepository = PieceRepository(modelContext: modelContext)
        self.sessionRepository = PracticeSessionRepository(modelContext: modelContext)
    }
    
    func loadProfileData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load practice statistics
            currentStreak = try await sessionRepository.getStreak()
            totalSessions = try await sessionRepository.getTotalSessionCount()
            
            // Load most practiced piece
            if let (pieceId, count) = try await sessionRepository.getMostPracticedPiece() {
                mostPracticedPiece = try await pieceRepository.fetch(by: pieceId)
                mostPracticedCount = count
            }
            
            // Load recent sessions
            let sessions = try await sessionRepository.getRecentSessions(limit: 10)
            var sessionsWithPieces: [SessionWithPiece] = []
            
            for session in sessions {
                if let piece = try await pieceRepository.fetch(by: session.pieceId) {
                    sessionsWithPieces.append(SessionWithPiece(session: session, piece: piece))
                }
            }
            
            recentSessions = sessionsWithPieces
            
            isLoading = false
        } catch {
            errorMessage = "Failed to load profile data: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func refresh() async {
        await loadProfileData()
    }
    
    func formatSessionDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    func formatSessionDuration(_ session: PracticeSession) -> String {
        guard let endTime = session.endTime else {
            return "In progress"
        }
        
        let duration = endTime.timeIntervalSince(session.startTime)
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

// Helper struct to combine session with piece data
struct SessionWithPiece: Identifiable {
    let session: PracticeSession
    let piece: Piece
    
    var id: UUID { session.id }
}
