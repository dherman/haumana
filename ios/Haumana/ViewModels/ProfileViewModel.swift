//
//  ProfileViewModel.swift
//  haumana
//
//  Created on 6/4/2025.
//

import Foundation
import SwiftData
import Observation
import UIKit

@MainActor
@Observable
final class ProfileViewModel {
    private let pieceRepository: PieceRepositoryProtocol
    private let sessionRepository: PracticeSessionRepositoryProtocol
    private let modelContext: ModelContext
    let authService: AuthenticationServiceProtocol
    
    // User info
    var isSignedIn: Bool { authService.isSignedIn }
    var currentUser: User? { authService.currentUser }
    var userName: String { currentUser?.displayName ?? "Haumana User" }
    var userEmail: String { currentUser?.email ?? "" }
    var userPhotoUrl: String? { currentUser?.photoUrl }
    
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
    
    // Test mode helpers
    #if DEBUG
    var isInTestMode: Bool {
        return KWSAPIClient.shared.isTestMode
    }
    #endif
    
    init(modelContext: ModelContext, authService: AuthenticationServiceProtocol) {
        self.modelContext = modelContext
        self.authService = authService
        self.pieceRepository = PieceRepository(modelContext: modelContext)
        self.sessionRepository = PracticeSessionRepository(modelContext: modelContext)
    }
    
    func loadProfileData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load practice statistics
            let userId = authService.currentUser?.id
            currentStreak = try await sessionRepository.getStreak(userId: userId)
            totalSessions = try await sessionRepository.getTotalSessionCount(userId: userId)
            
            // Load most practiced piece
            if let (pieceId, count) = try await sessionRepository.getMostPracticedPiece(userId: userId) {
                mostPracticedPiece = try pieceRepository.fetch(by: pieceId)
                mostPracticedCount = count
            }
            
            // Load recent sessions
            let sessions = try await sessionRepository.getRecentSessions(limit: 10, userId: userId)
            var sessionsWithPieces: [SessionWithPiece] = []
            
            for session in sessions {
                if let piece = try pieceRepository.fetch(by: session.pieceId) {
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
    
    func signIn(presenting viewController: UIViewController) async {
        do {
            try await authService.signIn(presenting: viewController)
            await loadProfileData()
        } catch {
            errorMessage = "Sign in failed: \(error.localizedDescription)"
        }
    }
    
    func signOut() {
        Task {
            await authService.signOut()
            // Clear any cached data
            currentStreak = 0
            totalSessions = 0
            mostPracticedPiece = nil
            mostPracticedCount = 0
            recentSessions = []
        }
    }
    
    func restorePreviousSignIn() async {
        await authService.restorePreviousSignIn()
        if authService.isSignedIn {
            await loadProfileData()
        }
    }
    
    // MARK: - Test Mode Methods
    #if DEBUG
    /// Simulates parent approval in test mode
    func simulateParentApproval() async {
        guard isInTestMode else {
            print("⚠️ simulateParentApproval only works in test mode")
            return
        }
        
        guard let userId = UserDefaults.standard.string(forKey: "testKWS_userId") else {
            print("⚠️ No test user ID found")
            return
        }
        
        print("🧪 TEST MODE: Simulating parent approval for user \(userId)")
        
        // Update test consent status
        UserDefaults.standard.set("approved", forKey: "testKWS_consentStatus")
        
        // Update the user's consent status in the database
        if let user = currentUser {
            user.parentConsentStatus = ParentConsentStatus.approved.rawValue
            user.parentConsentDate = Date()
            
            do {
                try modelContext.save()
                print("✅ Parent consent approved in test mode")
            } catch {
                print("❌ Failed to save consent status: \(error)")
            }
        }
    }
    
    /// Simulates parent denial in test mode
    func simulateParentDenial() async {
        guard isInTestMode else {
            print("⚠️ simulateParentDenial only works in test mode")
            return
        }
        
        guard let userId = UserDefaults.standard.string(forKey: "testKWS_userId") else {
            print("⚠️ No test user ID found")
            return
        }
        
        print("🧪 TEST MODE: Simulating parent denial for user \(userId)")
        
        // Update test consent status
        UserDefaults.standard.set("denied", forKey: "testKWS_consentStatus")
        
        // Update the user's consent status in the database
        if let user = currentUser {
            user.parentConsentStatus = ParentConsentStatus.denied.rawValue
            
            do {
                try modelContext.save()
                print("❌ Parent consent denied in test mode")
            } catch {
                print("❌ Failed to save consent status: \(error)")
            }
        }
    }
    #endif
}

// Helper struct to combine session with piece data
struct SessionWithPiece: Identifiable {
    let session: PracticeSession
    let piece: Piece
    
    var id: UUID { session.id }
}
