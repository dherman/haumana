//
//  AddEditPieceViewModel.swift
//  haumana
//
//  Created on 6/1/2025.
//

import Foundation
import SwiftData

@MainActor
final class AddEditPieceViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var category: PieceCategory = .oli
    @Published var lyrics: String = ""
    @Published var language: String = "haw"
    @Published var author: String = ""
    @Published var sourceUrl: String = ""
    @Published var notes: String = ""
    
    @Published var titleError: String?
    @Published var lyricsError: String?
    @Published var urlError: String?
    @Published var isSaving: Bool = false
    
    private let repository: PieceRepositoryProtocol
    private let authService: AuthenticationServiceProtocol?
    private let existingPiece: Piece?
    let isEditing: Bool
    
    private var userId: String? {
        authService?.currentUser?.id
    }
    
    init(piece: Piece? = nil, repository: PieceRepositoryProtocol, authService: AuthenticationServiceProtocol? = nil) {
        self.repository = repository
        self.authService = authService
        self.existingPiece = piece
        self.isEditing = piece != nil
        
        if let piece = piece {
            self.title = piece.title
            self.category = piece.categoryEnum
            self.lyrics = piece.lyrics
            self.language = piece.language
            self.author = piece.author ?? ""
            self.sourceUrl = piece.sourceUrl ?? ""
            self.notes = piece.notes ?? ""
        }
    }
    
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lyrics.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var hasChanges: Bool {
        guard let existing = existingPiece else { 
            return !title.isEmpty || !lyrics.isEmpty || !author.isEmpty || 
                   !sourceUrl.isEmpty || !notes.isEmpty
        }
        
        return title != existing.title ||
               category.rawValue != existing.category ||
               lyrics != existing.lyrics ||
               language != existing.language ||
               author != (existing.author ?? "") ||
               sourceUrl != (existing.sourceUrl ?? "") ||
               notes != (existing.notes ?? "")
    }
    
    func validateForm() -> Bool {
        var isValid = true
        
        titleError = nil
        lyricsError = nil
        urlError = nil
        
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            titleError = "Title is required"
            isValid = false
        } else if title.count > 4096 {
            titleError = "Title must be less than 4096 characters"
            isValid = false
        }
        
        if lyrics.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lyricsError = "Lyrics are required"
            isValid = false
        }
        
        if !sourceUrl.isEmpty {
            if let url = URL(string: sourceUrl), 
               url.scheme == nil || (url.scheme != "http" && url.scheme != "https") {
                urlError = "Please enter a valid URL"
            }
        }
        
        return isValid
    }
    
    func save() async -> Bool {
        print("AddEditPieceViewModel: save() called")
        guard validateForm() else { 
            print("AddEditPieceViewModel: Form validation failed")
            return false 
        }
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            if let existing = existingPiece {
                print("AddEditPieceViewModel: Updating existing piece: \(existing.title)")
                existing.title = title
                existing.category = category.rawValue
                existing.lyrics = lyrics
                existing.language = language
                existing.author = author.isEmpty ? nil : author
                existing.sourceUrl = sourceUrl.isEmpty ? nil : sourceUrl
                existing.notes = notes.isEmpty ? nil : notes
                
                try repository.update(existing)
            } else {
                let newPiece = Piece(
                    title: title,
                    category: category,
                    lyrics: lyrics,
                    language: language,
                    author: author.isEmpty ? nil : author,
                    sourceUrl: sourceUrl.isEmpty ? nil : sourceUrl,
                    notes: notes.isEmpty ? nil : notes
                )
                
                try repository.add(newPiece, userId: userId)
            }
            
            return true
        } catch {
            return false
        }
    }
}