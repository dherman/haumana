//
//  PieceDetailViewModel.swift
//  haumana
//
//  Created on 6/1/2025.
//

import Foundation
import SwiftData

@MainActor
final class PieceDetailViewModel: ObservableObject {
    @Published var piece: Piece
    @Published var errorMessage: String?
    
    private let repository: PieceRepositoryProtocol
    
    init(piece: Piece, repository: PieceRepositoryProtocol) {
        self.piece = piece
        self.repository = repository
    }
    
    func refresh() {
        do {
            if let updated = try repository.fetch(by: piece.id) {
                self.piece = updated
            }
            errorMessage = nil
        } catch {
            errorMessage = "Failed to refresh piece: \(error.localizedDescription)"
        }
    }
}