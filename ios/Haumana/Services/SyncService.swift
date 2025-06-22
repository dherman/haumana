//
//  SyncService.swift
//  haumana
//
//  Created on 6/18/2025.
//

import Foundation
import SwiftData

@MainActor
@Observable
class SyncService {
    private(set) var syncStatus: SyncStatus = .synced
    private(set) var lastSyncedAt: Date?
    private(set) var pendingChanges = 0
    
    private let modelContext: ModelContext
    private let authService: AuthenticationServiceProtocol
    private var syncTimer: Timer?
    private let syncInterval: TimeInterval = 300 // 5 minutes
    
    enum SyncStatus: Equatable {
        case synced
        case syncing
        case pendingChanges
        case offline
        case error(String)
    }
    
    init(modelContext: ModelContext, authService: AuthenticationServiceProtocol) {
        self.modelContext = modelContext
        self.authService = authService
        
        // Start monitoring auth state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(authStateChanged),
            name: NSNotification.Name("AuthStateChanged"),
            object: nil
        )
        
        // Monitor local data changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(localDataChanged),
            name: NSNotification.Name("LocalDataChanged"),
            object: nil
        )
        
        // Setup reachability monitoring
        setupReachability()
        
        // Start periodic sync if authenticated
        if authService.isSignedIn {
            startPeriodicSync()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    func syncNow() async {
        guard authService.isSignedIn else {
            print("SyncService: Cannot sync - user not signed in")
            return
        }
        
        guard syncStatus != .syncing else {
            print("SyncService: Sync already in progress")
            return
        }
        
        syncStatus = .syncing
        
        do {
            print("SyncService: Starting sync...")
            
            // Get Google ID token for authentication
            guard let idToken = try await authService.getCurrentIdToken() else {
                throw NSError(domain: "SyncService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authentication token available"])
            }
            
            // Sync pieces
            try await syncPieces(token: idToken)
            
            // Sync practice sessions
            try await syncSessions(token: idToken)
            
            lastSyncedAt = Date()
            syncStatus = .synced
            pendingChanges = 0
            
            print("SyncService: Sync completed successfully")
        } catch {
            print("SyncService: Sync error: \(error)")
            syncStatus = .error(error.localizedDescription)
        }
    }
    
    func markPendingChanges() {
        pendingChanges += 1
        if syncStatus == .synced {
            syncStatus = .pendingChanges
        }
    }
    
    // MARK: - Private Methods
    
    private func setupReachability() {
        // TODO: Implement network reachability monitoring
        // For now, assume we're always online
        print("SyncService: Network reachability monitoring not yet implemented")
    }
    
    @objc private func authStateChanged() {
        if authService.isSignedIn {
            startPeriodicSync()
            Task {
                await syncNow()
            }
        } else {
            stopPeriodicSync()
            syncStatus = .synced
            pendingChanges = 0
            lastSyncedAt = nil
        }
    }
    
    @objc private func localDataChanged() {
        markPendingChanges()
    }
    
    private func startPeriodicSync() {
        stopPeriodicSync()
        
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { _ in
            Task { @MainActor in
                if self.pendingChanges > 0 || self.shouldSyncBasedOnTime() {
                    await self.syncNow()
                }
            }
        }
    }
    
    private func stopPeriodicSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    private func shouldSyncBasedOnTime() -> Bool {
        guard let lastSync = lastSyncedAt else { return true }
        return Date().timeIntervalSince(lastSync) > syncInterval
    }
    
    // MARK: - Sync Methods
    
    private func syncPieces(token: String) async throws {
        let userId = authService.currentUser?.id ?? ""
        let repository = PieceRepository(modelContext: modelContext)
        let localPieces = try repository.fetchAll(userId: userId)
        
        // Prepare sync request
        let syncRequest = PiecesSyncRequest(
            operation: "sync",
            pieces: localPieces.map { piece in
                PieceSyncData(
                    pieceId: piece.id.uuidString,
                    userId: userId,
                    title: piece.title,
                    category: piece.category,
                    lyrics: piece.lyrics,
                    language: piece.language,
                    englishTranslation: piece.englishTranslation,
                    author: piece.author,
                    sourceUrl: piece.sourceUrl,
                    notes: piece.notes,
                    includeInPractice: piece.includeInPractice,
                    isFavorite: piece.isFavorite,
                    createdAt: piece.createdAt.ISO8601Format(),
                    modifiedAt: piece.updatedAt.ISO8601Format(),
                    lastSyncedAt: piece.lastSyncedAt?.ISO8601Format(),
                    version: piece.version,
                    locallyModified: piece.locallyModified
                )
            }.filter { $0.locallyModified },
            lastSyncedAt: lastSyncedAt?.ISO8601Format()
        )
        
        let encoder = JSONEncoder()
        let requestData = try encoder.encode(syncRequest)
        
        // Make API request
        guard let url = URL(string: "\(AppConstants.apiEndpoint)/pieces") else {
            throw NSError(domain: "SyncService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData
        
        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = httpResponse as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "SyncService", code: -1, userInfo: [NSLocalizedDescriptionKey: "API request failed"])
        }
        
        // Process response
        let decoder = JSONDecoder()
        let response = try decoder.decode(PiecesSyncResponse.self, from: data)
        
        // Update local pieces with server changes
        for serverPiece in response.serverPieces {
            if let existingPiece = localPieces.first(where: { $0.id.uuidString == serverPiece.pieceId }) {
                // Update existing piece if server version is newer
                if serverPiece.modifiedAt > existingPiece.updatedAt.ISO8601Format() {
                    existingPiece.title = serverPiece.title
                    existingPiece.category = serverPiece.category
                    existingPiece.lyrics = serverPiece.lyrics
                    existingPiece.language = serverPiece.language ?? "haw"
                    existingPiece.englishTranslation = serverPiece.englishTranslation
                    existingPiece.author = serverPiece.author
                    existingPiece.sourceUrl = serverPiece.sourceUrl
                    existingPiece.notes = serverPiece.notes
                    existingPiece.includeInPractice = serverPiece.includeInPractice
                    existingPiece.isFavorite = serverPiece.isFavorite
                    existingPiece.lastSyncedAt = Date()
                    existingPiece.locallyModified = false
                    existingPiece.version = serverPiece.version
                }
            } else {
                // Create new piece from server
                let newPiece = Piece(
                    title: serverPiece.title,
                    category: .oli, // Will be set below
                    lyrics: serverPiece.lyrics,
                    language: serverPiece.language ?? "haw",
                    englishTranslation: serverPiece.englishTranslation,
                    author: serverPiece.author,
                    sourceUrl: serverPiece.sourceUrl,
                    notes: serverPiece.notes
                )
                newPiece.id = UUID(uuidString: serverPiece.pieceId) ?? UUID()
                newPiece.userId = userId
                newPiece.category = serverPiece.category
                newPiece.includeInPractice = serverPiece.includeInPractice
                newPiece.isFavorite = serverPiece.isFavorite
                newPiece.lastSyncedAt = Date()
                newPiece.locallyModified = false
                newPiece.version = serverPiece.version
                
                modelContext.insert(newPiece)
            }
        }
        
        // Mark uploaded pieces as synced
        for piece in localPieces.filter({ $0.locallyModified }) {
            if response.uploadedPieces.contains(piece.id.uuidString) {
                piece.lastSyncedAt = Date()
                piece.locallyModified = false
            }
        }
        
        try modelContext.save()
    }
    
    private func syncSessions(token: String) async throws {
        let userId = authService.currentUser?.id ?? ""
        let repository = PracticeSessionRepository(modelContext: modelContext)
        
        // Get unsynced sessions
        let unsyncedSessions = try repository.fetchUnsyncedSessions(userId: userId)
        
        guard !unsyncedSessions.isEmpty else {
            print("SyncService: No practice sessions to sync")
            return
        }
        
        // Prepare sync request
        let syncRequest = SessionsSyncRequest(
            sessions: unsyncedSessions.map { session in
                SessionSyncData(
                    sessionId: session.id.uuidString,
                    userId: userId,
                    pieceId: session.pieceId.uuidString,
                    startedAt: session.startTime.ISO8601Format(),
                    endedAt: session.endTime?.ISO8601Format(),
                    createdAt: session.startTime.ISO8601Format()
                )
            }
        )
        
        let encoder = JSONEncoder()
        let requestData = try encoder.encode(syncRequest)
        
        // Make API request
        guard let url = URL(string: "\(AppConstants.apiEndpoint)/sessions") else {
            throw NSError(domain: "SyncService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData
        
        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = httpResponse as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "SyncService", code: -1, userInfo: [NSLocalizedDescriptionKey: "API request failed"])
        }
        
        // Process response
        let decoder = JSONDecoder()
        let syncResponse = try decoder.decode(SessionsSyncResponse.self, from: data)
        
        // Mark sessions as synced
        for sessionId in syncResponse.uploadedSessions {
            if let sessionUUID = UUID(uuidString: sessionId),
               let session = unsyncedSessions.first(where: { $0.id == sessionUUID }) {
                session.syncedAt = Date()
            }
        }
        
        try modelContext.save()
    }
}

// MARK: - Data Models

struct PiecesSyncRequest: Codable {
    let operation: String
    let pieces: [PieceSyncData]
    let lastSyncedAt: String?
}

struct PieceSyncData: Codable {
    let pieceId: String
    let userId: String
    let title: String
    let category: String
    let lyrics: String
    let language: String?
    let englishTranslation: String?
    let author: String?
    let sourceUrl: String?
    let notes: String?
    let includeInPractice: Bool
    let isFavorite: Bool
    let createdAt: String
    let modifiedAt: String
    let lastSyncedAt: String?
    let version: Int
    let locallyModified: Bool
}

struct PiecesSyncResponse: Codable {
    let serverPieces: [PieceSyncData]
    let uploadedPieces: [String]
    let syncedAt: String
}

struct SessionsSyncRequest: Codable {
    let sessions: [SessionSyncData]
}

struct SessionSyncData: Codable {
    let sessionId: String
    let userId: String
    let pieceId: String
    let startedAt: String
    let endedAt: String?
    let createdAt: String
}

struct SessionsSyncResponse: Codable {
    let uploadedSessions: [String]
    let syncedAt: String
}

// MARK: - Network Reachability Event

struct NetworkReachabilityEvent {
    let isOnline: Bool
}