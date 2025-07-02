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
    
    @MainActor
    func syncNow() async {
        print("SyncService: syncNow() called")
        
        guard authService.isSignedIn else {
            print("SyncService: Cannot sync - user not signed in")
            return
        }
        
        guard syncStatus != .syncing else {
            print("SyncService: Sync already in progress")
            return
        }
        
        syncStatus = .syncing
        
        defer {
            print("SyncService: syncNow() completing")
        }
        
        do {
            print("SyncService: Starting sync...")
            
            // Get Google ID token for authentication
            guard let idToken = try await authService.getCurrentIdToken() else {
                syncStatus = .error("No authentication token available")
                throw NSError(domain: "SyncService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authentication token available"])
            }
            
            // Log whether this is an initial sync
            if lastSyncedAt == nil {
                print("SyncService: Performing initial sync - fetching all pieces from server")
            } else {
                print("SyncService: Syncing changes since \(lastSyncedAt!.ISO8601Format())")
            }
            
            // Sync pieces
            let syncedTimestamp = try await syncPieces(token: idToken)
            
            // Sync practice sessions
            try await syncSessions(token: idToken)
            
            // Use server's timestamp to ensure consistency
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let serverDate = formatter.date(from: syncedTimestamp) {
                lastSyncedAt = serverDate
                print("SyncService: Updated lastSyncedAt to server time: \(syncedTimestamp)")
            } else {
                lastSyncedAt = Date()
            }
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
        print("SyncService: localDataChanged notification received")
        markPendingChanges()
        
        // Trigger immediate sync when data changes
        Task {
            print("SyncService: Triggering immediate sync due to local data change")
            await syncNow()
        }
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
    
    private func syncPieces(token: String) async throws -> String {
        let userId = authService.currentUser?.id ?? ""
        let repository = PieceRepository(modelContext: modelContext)
        let localPieces = try repository.fetchAll(userId: userId)
        
        // Log pieces being synced
        print("SyncService: Preparing to sync \(localPieces.count) pieces")
        let modifiedPieces = localPieces.filter { $0.locallyModified }
        print("SyncService: \(modifiedPieces.count) pieces have locallyModified = true")
        if modifiedPieces.count > 0 {
            modifiedPieces.forEach { piece in
                print("SyncService: Modified piece: \(piece.title) - locallyModified: \(piece.locallyModified)")
            }
        }
        
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
            },
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
        
        print("SyncService: Received sync response - syncedAt: \(response.syncedAt), serverPieces: \(response.serverPieces.count)")
        
        // Update local pieces with server changes
        for serverPiece in response.serverPieces {
            if let existingPiece = localPieces.first(where: { $0.id.uuidString == serverPiece.pieceId }) {
                // Update existing piece if server version is newer
                // Parse the ISO8601 date with or without fractional seconds
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                var serverModifiedDate = formatter.date(from: serverPiece.modifiedAt)
                
                // If parsing with fractional seconds fails, try without
                if serverModifiedDate == nil {
                    formatter.formatOptions = [.withInternetDateTime]
                    serverModifiedDate = formatter.date(from: serverPiece.modifiedAt)
                }
                
                let finalDate = serverModifiedDate ?? Date.distantPast
                
                print("SyncService: Comparing piece '\(serverPiece.title)':")
                print("  - Server modifiedAt: \(serverPiece.modifiedAt) (\(finalDate))")
                print("  - Local updatedAt: \(existingPiece.updatedAt)")
                print("  - Server version: \(serverPiece.version), Local version: \(existingPiece.version)")
                print("  - Local locallyModified: \(existingPiece.locallyModified)")
                
                // Update if server version is newer OR if timestamps indicate server is newer
                if serverPiece.version > existingPiece.version || 
                   (serverPiece.version == existingPiece.version && finalDate > existingPiece.updatedAt && !existingPiece.locallyModified) {
                    print("SyncService: Updating local piece with server version")
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
                    existingPiece.version = serverPiece.version
                    // Don't change locallyModified if we have local changes
                    if !existingPiece.locallyModified {
                        existingPiece.updatedAt = finalDate
                    }
                } else {
                    print("SyncService: Skipping update - local piece is same version or has local changes")
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
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let serverDate = dateFormatter.date(from: serverPiece.modifiedAt) {
                    newPiece.updatedAt = serverDate
                }
                if let serverCreatedDate = dateFormatter.date(from: serverPiece.createdAt) {
                    newPiece.createdAt = serverCreatedDate
                }
                
                modelContext.insert(newPiece)
            }
        }
        
        // Update uploaded pieces with server response
        if let updatedPieces = response.updatedPieces {
            for updatedPiece in updatedPieces {
                if let localPiece = localPieces.first(where: { $0.id.uuidString == updatedPiece.pieceId }) {
                    localPiece.version = updatedPiece.version
                    localPiece.lastSyncedAt = Date()
                    localPiece.locallyModified = false
                    
                    // Update modifiedAt from server
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let serverDate = formatter.date(from: updatedPiece.modifiedAt) {
                        localPiece.updatedAt = serverDate
                    }
                    
                    print("SyncService: Updated piece '\(localPiece.title)' to version \(localPiece.version) after successful upload")
                }
            }
        } else {
            // Fallback for older server versions
            for piece in localPieces.filter({ $0.locallyModified }) {
                if response.uploadedPieces.contains(piece.id.uuidString) {
                    piece.lastSyncedAt = Date()
                    piece.locallyModified = false
                }
            }
        }
        
        // Save all changes
        do {
            try modelContext.save()
            print("SyncService: Successfully synced \(response.uploadedPieces.count) local changes and \(response.serverPieces.count) remote changes")
        } catch {
            print("SyncService: Failed to save sync changes: \(error)")
            throw error
        }
        
        // Return the server's sync timestamp
        return response.syncedAt
    }
    
    private func syncSessions(token: String) async throws {
        let userId = authService.currentUser?.id ?? ""
        let repository = PracticeSessionRepository(modelContext: modelContext)
        
        // Get unsynced sessions
        let unsyncedSessions = try repository.fetchUnsyncedSessions(userId: userId)
        
        print("SyncService: Starting session sync for user \(userId)")
        print("SyncService: Found \(unsyncedSessions.count) unsynced sessions to upload")
        
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
        
        print("SyncService: Session sync response - uploaded: \(syncResponse.uploadedSessions.count), server sessions: \(syncResponse.serverSessions?.count ?? 0)")
        
        // Mark uploaded sessions as synced
        for sessionId in syncResponse.uploadedSessions {
            if let sessionUUID = UUID(uuidString: sessionId),
               let session = unsyncedSessions.first(where: { $0.id == sessionUUID }) {
                session.syncedAt = Date()
            }
        }
        
        // Process downloaded sessions from server
        if let serverSessions = syncResponse.serverSessions {
            print("SyncService: Processing \(serverSessions.count) sessions from server for user \(userId)")
            
            for serverSession in serverSessions {
                // Check if session already exists locally
                let sessionUUID = UUID(uuidString: serverSession.sessionId) ?? UUID()
                let descriptor = FetchDescriptor<PracticeSession>(
                    predicate: #Predicate { session in
                        session.id == sessionUUID
                    }
                )
                
                let existingSessions = try modelContext.fetch(descriptor)
                
                if existingSessions.isEmpty {
                    // Create new session from server data
                    let pieceUUID = UUID(uuidString: serverSession.pieceId) ?? UUID()
                    
                    print("SyncService: Creating new session - sessionId: \(serverSession.sessionId), pieceId: \(serverSession.pieceId), userId: \(serverSession.userId)")
                    
                    // Parse dates
                    let dateFormatter = ISO8601DateFormatter()
                    dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    var startTime = dateFormatter.date(from: serverSession.startedAt)
                    
                    // Try without fractional seconds if parsing fails
                    if startTime == nil {
                        dateFormatter.formatOptions = [.withInternetDateTime]
                        startTime = dateFormatter.date(from: serverSession.startedAt)
                    }
                    
                    let newSession = PracticeSession(
                        pieceId: pieceUUID,
                        startTime: startTime ?? Date()
                    )
                    newSession.id = sessionUUID
                    newSession.userId = userId
                    newSession.syncedAt = Date()
                    
                    // Parse end time if available
                    if let endedAtString = serverSession.endedAt {
                        newSession.endTime = dateFormatter.date(from: endedAtString)
                    }
                    
                    modelContext.insert(newSession)
                    print("SyncService: Created new session from server: \(serverSession.sessionId) for piece: \(pieceUUID)")
                }
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
    let updatedPieces: [PieceSyncData]?
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
    let serverSessions: [SessionSyncData]?
    let syncedAt: String
}

// MARK: - Network Reachability Event

struct NetworkReachabilityEvent {
    let isOnline: Bool
}