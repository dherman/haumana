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
    func fetchAll(userId: String?) throws -> [Piece]
    func fetch(by id: UUID) throws -> Piece?
    func add(_ piece: Piece, userId: String?) throws
    func update(_ piece: Piece) throws
    func delete(_ piece: Piece) throws
    func search(query: String, userId: String?) throws -> [Piece]
    func fetchPracticeEligible(userId: String?) throws -> [Piece]
    func fetchFavorites(userId: String?) throws -> [Piece]
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
    
    func fetchAll(userId: String? = nil) throws -> [Piece] {
        let descriptor: FetchDescriptor<Piece>
        if let userId = userId {
            descriptor = FetchDescriptor<Piece>(
                predicate: #Predicate { piece in
                    piece.userId == userId
                },
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
        } else {
            // For unauthenticated users, show pieces without userId
            descriptor = FetchDescriptor<Piece>(
                predicate: #Predicate { piece in
                    piece.userId == nil
                },
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
        }
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
    
    func add(_ piece: Piece, userId: String? = nil) throws {
        piece.userId = userId
        modelContext.insert(piece)
        try modelContext.save()
        
        // Notify sync service
        NotificationCenter.default.post(name: NSNotification.Name("LocalDataChanged"), object: nil)
    }
    
    func update(_ piece: Piece) throws {
        piece.updatedAt = Date()
        piece.locallyModified = true
        piece.version += 1
        try modelContext.save()
        
        // Notify sync service
        NotificationCenter.default.post(name: NSNotification.Name("LocalDataChanged"), object: nil)
    }
    
    func delete(_ piece: Piece) throws {
        modelContext.delete(piece)
        try modelContext.save()
        
        // Notify sync service
        NotificationCenter.default.post(name: NSNotification.Name("LocalDataChanged"), object: nil)
    }
    
    func search(query: String, userId: String? = nil) throws -> [Piece] {
        let descriptor: FetchDescriptor<Piece>
        if let userId = userId {
            descriptor = FetchDescriptor<Piece>(
                predicate: #Predicate { piece in
                    piece.userId == userId &&
                    (piece.title.localizedStandardContains(query) ||
                     piece.lyrics.localizedStandardContains(query) ||
                     (piece.author != nil && piece.author!.localizedStandardContains(query)))
                },
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<Piece>(
                predicate: #Predicate { piece in
                    piece.userId == nil &&
                    (piece.title.localizedStandardContains(query) ||
                     piece.lyrics.localizedStandardContains(query) ||
                     (piece.author != nil && piece.author!.localizedStandardContains(query)))
                },
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
        }
        return try modelContext.fetch(descriptor)
    }
    
    func fetchPracticeEligible(userId: String? = nil) throws -> [Piece] {
        let descriptor: FetchDescriptor<Piece>
        if let userId = userId {
            descriptor = FetchDescriptor<Piece>(
                predicate: #Predicate { piece in
                    piece.userId == userId && piece.includeInPractice == true
                },
                sortBy: [SortDescriptor(\.title)]
            )
        } else {
            descriptor = FetchDescriptor<Piece>(
                predicate: #Predicate { piece in
                    piece.userId == nil && piece.includeInPractice == true
                },
                sortBy: [SortDescriptor(\.title)]
            )
        }
        return try modelContext.fetch(descriptor)
    }
    
    func fetchFavorites(userId: String? = nil) throws -> [Piece] {
        let descriptor: FetchDescriptor<Piece>
        if let userId = userId {
            descriptor = FetchDescriptor<Piece>(
                predicate: #Predicate { piece in
                    piece.userId == userId && piece.isFavorite == true
                },
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<Piece>(
                predicate: #Predicate { piece in
                    piece.userId == nil && piece.isFavorite == true
                },
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
        }
        return try modelContext.fetch(descriptor)
    }
    
    func toggleFavorite(_ piece: Piece) throws {
        piece.isFavorite.toggle()
        piece.updatedAt = Date()
        piece.locallyModified = true
        piece.version += 1
        try modelContext.save()
        
        // Notify sync service
        NotificationCenter.default.post(name: NSNotification.Name("LocalDataChanged"), object: nil)
    }
    
    func toggleIncludeInPractice(_ piece: Piece) throws {
        piece.includeInPractice.toggle()
        piece.updatedAt = Date()
        piece.locallyModified = true
        piece.version += 1
        try modelContext.save()
        
        // Notify sync service
        NotificationCenter.default.post(name: NSNotification.Name("LocalDataChanged"), object: nil)
    }
    
    func updateLastPracticed(_ piece: Piece) throws {
        piece.lastPracticed = Date()
        piece.updatedAt = Date()
        piece.locallyModified = true
        piece.version += 1
        try modelContext.save()
        
        // Notify sync service
        NotificationCenter.default.post(name: NSNotification.Name("LocalDataChanged"), object: nil)
    }
}