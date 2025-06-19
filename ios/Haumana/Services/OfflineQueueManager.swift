//
//  OfflineQueueManager.swift
//  haumana
//
//  Created on 6/18/2025.
//

import Foundation
import SwiftData

@Model
final class SyncQueueItem {
    var id: UUID = UUID()
    var entityType: String // "piece" or "session"
    var entityId: String
    var operation: String // "create", "update", "delete"
    var timestamp: Date = Date()
    var retryCount: Int = 0
    var lastError: String?
    var userId: String?
    
    init(entityType: String, entityId: String, operation: String, userId: String? = nil) {
        self.id = UUID()
        self.entityType = entityType
        self.entityId = entityId
        self.operation = operation
        self.timestamp = Date()
        self.retryCount = 0
        self.userId = userId
    }
}

@MainActor
class OfflineQueueManager {
    private let modelContext: ModelContext
    private let maxRetries = 3
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func enqueue(entityType: String, entityId: String, operation: String, userId: String? = nil) {
        let item = SyncQueueItem(
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            userId: userId
        )
        modelContext.insert(item)
        try? modelContext.save()
    }
    
    func processQueue() async throws {
        let descriptor = FetchDescriptor<SyncQueueItem>(
            predicate: #Predicate { item in
                item.retryCount < 3
            },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        
        let items = try modelContext.fetch(descriptor)
        
        for item in items {
            do {
                try await processItem(item)
                modelContext.delete(item)
            } catch {
                item.retryCount += 1
                item.lastError = error.localizedDescription
            }
        }
        
        try modelContext.save()
    }
    
    func getQueueCount() throws -> Int {
        let descriptor = FetchDescriptor<SyncQueueItem>(
            predicate: #Predicate { item in
                item.retryCount < 3
            }
        )
        
        return try modelContext.fetchCount(descriptor)
    }
    
    private func processItem(_ item: SyncQueueItem) async throws {
        // This will be implemented by the SyncService
        // For now, just throw an error to indicate it needs processing
        throw SyncError.queueItemNotProcessed
    }
}

enum SyncError: LocalizedError {
    case queueItemNotProcessed
    case unknownEntityType
    case networkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .queueItemNotProcessed:
            return "Queue item awaiting processing"
        case .unknownEntityType:
            return "Unknown entity type in sync queue"
        case .networkUnavailable:
            return "Network is unavailable"
        }
    }
}