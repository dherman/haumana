//
//  PracticeSession.swift
//  haumana
//
//  Created on 6/3/2025.
//

import Foundation
import SwiftData

@Model
final class PracticeSession: Identifiable {
    var id: UUID = UUID()
    var pieceId: UUID
    var startTime: Date
    var endTime: Date?
    var userId: String?
    
    // Sync-related properties
    var syncedAt: Date?
    
    init(pieceId: UUID, startTime: Date = Date()) {
        self.id = UUID()
        self.pieceId = pieceId
        self.startTime = startTime
        self.endTime = nil
    }
    
    func end() {
        self.endTime = Date()
    }
    
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
}