//
//  SyncStatusView.swift
//  haumana
//
//  Created on 6/18/2025.
//

import SwiftUI

struct SyncStatusView: View {
    @Environment(\.syncService) private var syncService
    
    var body: some View {
        if let syncService = syncService {
            HStack(spacing: 8) {
                statusIcon(for: syncService.syncStatus)
                
                Text(statusText(for: syncService.syncStatus))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(16)
        }
    }
    
    @ViewBuilder
    private func statusIcon(for status: SyncService.SyncStatus) -> some View {
        switch status {
        case .synced:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .syncing:
            ProgressView()
                .scaleEffect(0.8)
        case .pendingChanges:
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundColor(.orange)
        case .offline:
            Image(systemName: "wifi.slash")
                .foregroundColor(.gray)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
        }
    }
    
    private func statusText(for status: SyncService.SyncStatus) -> String {
        switch status {
        case .synced:
            if let lastSync = syncService?.lastSyncedAt {
                return "Synced \(lastSync.formatted(.relative(presentation: .named)))"
            }
            return "Synced"
        case .syncing:
            return "Syncing..."
        case .pendingChanges:
            return "\(syncService?.pendingChanges ?? 0) pending"
        case .offline:
            return "Offline"
        case .error(_):
            return "Sync error"
        }
    }
}