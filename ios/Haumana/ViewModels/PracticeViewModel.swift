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
    private var lastPracticedPieceId: UUID?
    private var carouselMetrics = CarouselMetrics()
    private var lastEligiblePieceIds: Set<UUID> = []
    
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
            let allPieces = try pieceRepository.fetchAll()
            totalPieces = allPieces.count
            practiceEligibleCount = allPieces.filter { $0.includeInPractice }.count
            currentStreak = try await sessionRepository.getStreak()
            
            // Track eligible piece IDs
            let currentEligibleIds = Set(allPieces.filter { $0.includeInPractice }.map { $0.id })
            if lastEligiblePieceIds.isEmpty {
                lastEligiblePieceIds = currentEligibleIds
            }
            
            // Initialize suggestion queue if needed
            if suggestionQueue.isEmpty && practiceEligibleCount > 0 {
                await loadSuggestionQueue()
            }
        } catch {
            print("Error loading statistics: \(error)")
        }
    }
    
    func refreshCarousel() async {
        do {
            let allPieces = try pieceRepository.fetchAll()
            let eligiblePieces = allPieces.filter { $0.includeInPractice }
            let currentEligibleIds = Set(eligiblePieces.map { $0.id })
            
            // Check if the set of eligible pieces has changed
            if currentEligibleIds != lastEligiblePieceIds {
                print("Eligible pieces changed: \(lastEligiblePieceIds.count) -> \(currentEligibleIds.count)")
                
                // Update tracked state
                lastEligiblePieceIds = currentEligibleIds
                practiceEligibleCount = eligiblePieces.count
                totalPieces = allPieces.count
                
                // Clear and reload suggestion queue
                suggestionQueue.removeAll()
                currentCarouselIndex = 0
                
                if practiceEligibleCount > 0 {
                    await loadSuggestionQueue()
                }
            }
        } catch {
            print("Error refreshing carousel: \(error)")
        }
    }
    
    func startPracticeSession() async {
        do {
            isLoading = true
            errorMessage = nil
            
            // Get a random piece
            guard let piece = try selectionService.selectRandomPiece() else {
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
                guard let piece = try selectionService.getNextPiece(excluding: excludedIds) else {
                    // If no more pieces, wrap around
                    guard let piece = try selectionService.selectRandomPiece() else {
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
            try pieceRepository.toggleFavorite(piece)
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
        // Don't overwrite currentPiece if it's already set (from carousel selection)
        if currentPiece == nil {
            currentPiece = piece
            lastPracticedPieceId = piece.id
        }
        
        // Update piece's last practiced date
        do {
            try pieceRepository.updateLastPracticed(piece)
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
            suggestionQueue = try selectionService.generateSuggestionQueue(count: suggestionQueueSize)
            currentCarouselIndex = 0
            
            // Reset carousel metrics for new browsing session
            carouselMetrics = CarouselMetrics()
            
            // Track initial piece shown
            if !suggestionQueue.isEmpty {
                carouselMetrics.recordBrowse(pieceId: suggestionQueue[0].id)
            }
        } catch {
            print("Error loading suggestion queue: \(error)")
            errorMessage = "Error loading suggestions"
        }
    }
    
    func refreshSuggestionQueue() async {
        do {
            suggestionQueue = try selectionService.refreshSuggestionQueue(
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
        
        // Track carousel selection
        carouselMetrics.recordSelection(pieceId: selectedPiece.id, at: index)
        print(carouselMetrics.toBrowsingLog())
        
        // Just set the current piece - don't start session yet
        currentPiece = selectedPiece
        lastPracticedPieceId = selectedPiece.id
        
        // Don't update carousel yet - wait until practice screen is dismissed
    }
    
    func beginSelectedPractice() async {
        guard let piece = currentPiece else { return }
        
        // Now actually start the session
        await startSessionForPiece(piece)
    }
    
    func updateCarouselAfterPractice() async {
        // Find the practiced piece in the queue using the stored ID
        guard let practicedId = lastPracticedPieceId,
              let index = suggestionQueue.firstIndex(where: { $0.id == practicedId }) else { 
            // If piece not found, just refresh the queue
            await refreshSuggestionQueue()
            return 
        }
        
        // Remove the practiced piece from queue
        suggestionQueue.remove(at: index)
        
        // If we removed the current carousel item, adjust the index
        if index == currentCarouselIndex && currentCarouselIndex > 0 {
            currentCarouselIndex -= 1
        } else if index < currentCarouselIndex {
            currentCarouselIndex = max(0, currentCarouselIndex - 1)
        }
        
        // Refresh the queue to maintain the desired count
        await refreshSuggestionQueue()
        
        // Reset carousel index if it's out of bounds
        if currentCarouselIndex >= suggestionQueue.count {
            currentCarouselIndex = max(0, suggestionQueue.count - 1)
        }
        
        // Clear the stored ID
        lastPracticedPieceId = nil
    }
    
    func moveCarouselToNext() {
        guard !suggestionQueue.isEmpty else { return }
        currentCarouselIndex = (currentCarouselIndex + 1) % suggestionQueue.count
        
        // Track browsing
        if currentCarouselIndex < suggestionQueue.count {
            carouselMetrics.recordBrowse(pieceId: suggestionQueue[currentCarouselIndex].id)
        }
    }
    
    func moveCarouselToPrevious() {
        guard !suggestionQueue.isEmpty else { return }
        currentCarouselIndex = currentCarouselIndex == 0 ? suggestionQueue.count - 1 : currentCarouselIndex - 1
        
        // Track browsing
        if currentCarouselIndex < suggestionQueue.count {
            carouselMetrics.recordBrowse(pieceId: suggestionQueue[currentCarouselIndex].id)
        }
    }
}