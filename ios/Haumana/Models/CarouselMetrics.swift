//
//  CarouselMetrics.swift
//  haumana
//
//  Created on 6/6/2025.
//

import Foundation

struct CarouselMetrics {
    var sessionId: UUID = UUID()
    var startTime: Date = Date()
    var piecesBrowsed: Set<UUID> = []
    var browsingDuration: TimeInterval = 0
    var selectionIndex: Int?
    var selectedPieceId: UUID?
    
    mutating func recordBrowse(pieceId: UUID) {
        piecesBrowsed.insert(pieceId)
    }
    
    mutating func recordSelection(pieceId: UUID, at index: Int) {
        selectedPieceId = pieceId
        selectionIndex = index
        browsingDuration = Date().timeIntervalSince(startTime)
    }
    
    func toBrowsingLog() -> String {
        let browsedCount = piecesBrowsed.count
        let duration = String(format: "%.1f", browsingDuration)
        let selected = selectedPieceId != nil ? "selected at index \(selectionIndex ?? -1)" : "no selection"
        return "Carousel session: browsed \(browsedCount) pieces in \(duration)s, \(selected)"
    }
}