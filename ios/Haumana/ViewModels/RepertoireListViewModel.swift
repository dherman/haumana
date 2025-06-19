//
//  RepertoireListViewModel.swift
//  haumana
//
//  Created on 6/1/2025.
//

import Foundation
import SwiftData

@MainActor
final class RepertoireListViewModel: ObservableObject {
    @Published var pieces: [Piece] = []
    @Published var searchText: String = ""
    @Published var isSearching: Bool = false
    @Published var errorMessage: String?
    
    private let repository: PieceRepositoryProtocol
    private let authService: AuthenticationServiceProtocol?
    
    private var userId: String? {
        authService?.currentUser?.id
    }
    
    init(repository: PieceRepositoryProtocol, authService: AuthenticationServiceProtocol? = nil) {
        self.repository = repository
        self.authService = authService
    }
    
    func loadPieces() {
        do {
            pieces = try repository.fetchAll(userId: userId)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load pieces: \(error.localizedDescription)"
        }
    }
    
    func searchPieces() {
        guard !searchText.isEmpty else {
            loadPieces()
            return
        }
        
        do {
            pieces = try repository.search(query: searchText, userId: userId)
            errorMessage = nil
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
        }
    }
    
    func deletePiece(_ piece: Piece) {
        do {
            try repository.delete(piece)
            loadPieces()
        } catch {
            errorMessage = "Failed to delete piece: \(error.localizedDescription)"
        }
    }
    
    func clearSearch() {
        searchText = ""
        isSearching = false
        loadPieces()
    }
}