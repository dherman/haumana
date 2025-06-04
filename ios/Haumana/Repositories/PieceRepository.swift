//
//  PieceRepository.swift
//  haumana
//
//  Created on 6/1/2025.
//

import Foundation
import SwiftData

@MainActor
protocol PieceRepositoryProtocol {
    func fetchAll() throws -> [Piece]
    func fetch(by id: UUID) throws -> Piece?
    func add(_ piece: Piece) throws
    func update(_ piece: Piece) throws
    func delete(_ piece: Piece) throws
    func search(query: String) throws -> [Piece]
    func fetchPracticeEligible() throws -> [Piece]
    func fetchFavorites() throws -> [Piece]
    func toggleFavorite(_ piece: Piece) throws
    func toggleIncludeInPractice(_ piece: Piece) throws
    func updateLastPracticed(_ piece: Piece) throws
}

@MainActor
final class PieceRepository: PieceRepositoryProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchAll() throws -> [Piece] {
        let descriptor = FetchDescriptor<Piece>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetch(by id: UUID) throws -> Piece? {
        let descriptor = FetchDescriptor<Piece>(
            predicate: #Predicate { piece in
                piece.id == id
            }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    func add(_ piece: Piece) throws {
        modelContext.insert(piece)
        try modelContext.save()
    }
    
    func update(_ piece: Piece) throws {
        piece.updatedAt = Date()
        try modelContext.save()
    }
    
    func delete(_ piece: Piece) throws {
        modelContext.delete(piece)
        try modelContext.save()
    }
    
    func search(query: String) throws -> [Piece] {
        let descriptor = FetchDescriptor<Piece>(
            predicate: #Predicate { piece in
                piece.title.localizedStandardContains(query) ||
                piece.lyrics.localizedStandardContains(query) ||
                (piece.author != nil && piece.author!.localizedStandardContains(query))
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchPracticeEligible() throws -> [Piece] {
        let descriptor = FetchDescriptor<Piece>(
            predicate: #Predicate { piece in
                piece.includeInPractice == true
            },
            sortBy: [SortDescriptor(\.title)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchFavorites() throws -> [Piece] {
        let descriptor = FetchDescriptor<Piece>(
            predicate: #Predicate { piece in
                piece.isFavorite == true
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func toggleFavorite(_ piece: Piece) throws {
        piece.isFavorite.toggle()
        piece.updatedAt = Date()
        try modelContext.save()
    }
    
    func toggleIncludeInPractice(_ piece: Piece) throws {
        piece.includeInPractice.toggle()
        piece.updatedAt = Date()
        try modelContext.save()
    }
    
    func updateLastPracticed(_ piece: Piece) throws {
        piece.lastPracticed = Date()
        piece.updatedAt = Date()
        try modelContext.save()
    }
}