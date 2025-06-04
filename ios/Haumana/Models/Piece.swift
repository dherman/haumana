//
//  Piece.swift
//  haumana
//
//  Created on 6/1/2025.
//

import Foundation
import SwiftData

enum PieceCategory: String, Codable, CaseIterable {
    case oli = "oli"
    case mele = "mele"
    
    var displayName: String {
        switch self {
        case .oli:
            return "Oli"
        case .mele:
            return "Mele"
        }
    }
}

@Model
final class Piece: Identifiable {
    var id: UUID = UUID()
    var title: String = ""
    var category: String = PieceCategory.oli.rawValue
    var lyrics: String = ""
    var language: String = "haw"  // ISO 639 code
    var englishTranslation: String?
    var author: String?
    var sourceUrl: String?
    var notes: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var isFavorite: Bool = false
    var includeInPractice: Bool = true
    var lastPracticed: Date?
    
    init(
        title: String,
        category: PieceCategory = .oli,
        lyrics: String,
        language: String = "haw",
        englishTranslation: String? = nil,
        author: String? = nil,
        sourceUrl: String? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.category = category.rawValue
        self.lyrics = lyrics
        self.language = language
        self.englishTranslation = englishTranslation
        self.author = author
        self.sourceUrl = sourceUrl
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var categoryEnum: PieceCategory {
        PieceCategory(rawValue: category) ?? .oli
    }
    
    var displayLanguage: String {
        switch language {
        case "haw":
            return "ʻŌlelo Hawaiʻi"
        case "eng":
            return "English"
        default:
            return language
        }
    }
    
    var lyricsPreview: String {
        let lines = lyrics.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .prefix(3)
        return lines.joined(separator: "\n")
    }
}