//
//  PracticeViewModel.swift
//  haumana
//
//  Created on 6/3/2025.
//

import Foundation
import SwiftData
import Observation
import UIKit

@MainActor
@Observable
final class PracticeViewModel {
    private let pieceRepository: PieceRepositoryProtocol
    private let sessionRepository: PracticeSessionRepositoryProtocol
    private let selectionService: PracticeSelectionServiceProtocol
    private let modelContext: ModelContext
    
    // Current practice state
    var currentPiece: Piece?
    var currentSession: PracticeSession?
    var sessionHistory: [Piece] = []
    var currentHistoryIndex: Int = -1
    
    // Carousel state
    var suggestionQueue: [Piece] = []
    var currentCarouselIndex: Int = 0
    private let suggestionQueueSize = 7
    
    // UI State
    var isLoading = false
    var errorMessage: String?
    
    // Statistics
    var totalPieces: Int = 0
    var practiceEligibleCount: Int = 0
    var currentStreak: Int = 0
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.pieceRepository = PieceRepository(modelContext: modelContext)
        self.sessionRepository = PracticeSessionRepository(modelContext: modelContext)
        self.selectionService = PracticeSelectionService(
            pieceRepository: pieceRepository,
            modelContext: modelContext
        )
        
        // Listen for app lifecycle events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleAppBackground() {
        Task { @MainActor in
            await endCurrentSession()
        }
    }
    
    func loadStatistics() async {
        do {
            let allPieces = try await pieceRepository.fetchAll()
            totalPieces = allPieces.count
            practiceEligibleCount = allPieces.filter { $0.includeInPractice }.count
            currentStreak = try await sessionRepository.getStreak()
            
            // Initialize suggestion queue if needed
            if suggestionQueue.isEmpty && practiceEligibleCount > 0 {
                await loadSuggestionQueue()
            }
        } catch {
            print("Error loading statistics: \(error)")
        }
    }
    
    func startPracticeSession() async {
        do {
            isLoading = true
            errorMessage = nil
            
            // Get a random piece
            guard let piece = try await selectionService.selectRandomPiece() else {
                errorMessage = "No pieces available for practice"
                isLoading = false
                return
            }
            
            // Start a new session
            await startSessionForPiece(piece)
            
            isLoading = false
        } catch {
            errorMessage = "Error starting practice: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func nextPiece() async {
        // If we're not at the end of history, move forward in history
        if currentHistoryIndex < sessionHistory.count - 1 {
            currentHistoryIndex += 1
            await endCurrentSession()
            await startSessionForPiece(sessionHistory[currentHistoryIndex])
        } else {
            // Get a new random piece
            do {
                let excludedIds = sessionHistory.map { $0.id }
                guard let piece = try await selectionService.getNextPiece(excluding: excludedIds) else {
                    // If no more pieces, wrap around
                    guard let piece = try await selectionService.selectRandomPiece() else {
                        errorMessage = "No pieces available"
                        return
                    }
                    sessionHistory = [piece]
                    currentHistoryIndex = 0
                    await endCurrentSession()
                    await startSessionForPiece(piece)
                    return
                }
                
                await endCurrentSession()
                await startSessionForPiece(piece)
            } catch {
                errorMessage = "Error getting next piece: \(error.localizedDescription)"
            }
        }
    }
    
    func previousPiece() async {
        guard currentHistoryIndex > 0 else { return }
        
        currentHistoryIndex -= 1
        await endCurrentSession()
        await startSessionForPiece(sessionHistory[currentHistoryIndex])
    }
    
    func endPractice() async {
        await endCurrentSession()
        currentPiece = nil
        sessionHistory = []
        currentHistoryIndex = -1
    }
    
    func toggleFavorite() async {
        guard let piece = currentPiece else { return }
        
        do {
            try await pieceRepository.toggleFavorite(piece)
        } catch {
            print("Error toggling favorite: \(error)")
        }
    }
    
    func startSessionForSpecificPiece(_ piece: Piece) async {
        await endCurrentSession()
        sessionHistory = [piece]
        currentHistoryIndex = 0
        await startSessionForPiece(piece)
    }
    
    // MARK: - Private Methods
    
    private func startSessionForPiece(_ piece: Piece) async {
        currentPiece = piece
        
        // Update piece's last practiced date
        do {
            try await pieceRepository.updateLastPracticed(piece)
        } catch {
            print("Error updating last practiced: \(error)")
        }
        
        // Create new session
        let session = PracticeSession(pieceId: piece.id)
        currentSession = session
        
        // Add to history if it's a new piece
        if currentHistoryIndex == sessionHistory.count - 1 || sessionHistory.isEmpty {
            sessionHistory.append(piece)
            currentHistoryIndex = sessionHistory.count - 1
        }
        
        // Save session
        do {
            try await sessionRepository.save(session)
        } catch {
            print("Error saving session: \(error)")
        }
    }
    
    private func endCurrentSession() async {
        guard let session = currentSession else { return }
        
        session.end()
        
        do {
            try await sessionRepository.save(session)
        } catch {
            print("Error ending session: \(error)")
        }
        
        currentSession = nil
    }
    
    // MARK: - Carousel Methods
    
    func loadSuggestionQueue() async {
        do {
            suggestionQueue = try await selectionService.generateSuggestionQueue(count: suggestionQueueSize)
            currentCarouselIndex = 0
        } catch {
            print("Error loading suggestion queue: \(error)")
            errorMessage = "Error loading suggestions"
        }
    }
    
    func refreshSuggestionQueue() async {
        do {
            suggestionQueue = try await selectionService.refreshSuggestionQueue(
                currentQueue: suggestionQueue,
                count: suggestionQueueSize
            )
        } catch {
            print("Error refreshing suggestion queue: \(error)")
        }
    }
    
    func selectPieceFromCarousel(at index: Int) async {
        guard index >= 0 && index < suggestionQueue.count else { return }
        
        let selectedPiece = suggestionQueue[index]
        currentCarouselIndex = index
        
        // Start practice session with selected piece
        await startSessionForPiece(selectedPiece)
        
        // Remove the selected piece from queue and refresh
        suggestionQueue.remove(at: index)
        await refreshSuggestionQueue()
        
        // Reset carousel index if needed
        if currentCarouselIndex >= suggestionQueue.count {
            currentCarouselIndex = max(0, suggestionQueue.count - 1)
        }
    }
    
    func moveCarouselToNext() {
        guard !suggestionQueue.isEmpty else { return }
        currentCarouselIndex = (currentCarouselIndex + 1) % suggestionQueue.count
    }
    
    func moveCarouselToPrevious() {
        guard !suggestionQueue.isEmpty else { return }
        currentCarouselIndex = currentCarouselIndex == 0 ? suggestionQueue.count - 1 : currentCarouselIndex - 1
    }
}