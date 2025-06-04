//
//  ProfileTabView.swift
//  haumana
//
//  Created on 6/3/2025.
//

import SwiftUI
import SwiftData

struct ProfileTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PracticeSession.startTime, order: .reverse) private var sessions: [PracticeSession]
    @Query private var pieces: [Piece]
    
    private var totalSessions: Int {
        sessions.count
    }
    
    private var currentStreak: Int {
        // TODO: Calculate actual streak
        return 0
    }
    
    private var mostPracticedPiece: Piece? {
        guard !sessions.isEmpty else { return nil }
        
        let pieceCounts = Dictionary(grouping: sessions, by: { $0.pieceId })
            .mapValues { $0.count }
        
        guard let mostPracticedId = pieceCounts.max(by: { $0.value < $1.value })?.key else {
            return nil
        }
        
        return pieces.first { $0.id == mostPracticedId }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // User Section
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Guest User")
                                .font(.headline)
                            Text("Sign in coming in Milestone 3")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // Practice Stats Section
                Section("Practice Statistics") {
                    HStack {
                        Label("Current Streak", systemImage: "flame")
                        Spacer()
                        Text("\(currentStreak) days")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Total Sessions", systemImage: "music.note")
                        Spacer()
                        Text("\(totalSessions)")
                            .foregroundColor(.secondary)
                    }
                    
                    if let mostPracticed = mostPracticedPiece {
                        HStack {
                            Label("Most Practiced", systemImage: "star")
                            Spacer()
                            Text(mostPracticed.title)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                // Recent Practice History
                if !sessions.isEmpty {
                    Section("Recent Practice") {
                        ForEach(Array(sessions.prefix(10)), id: \.id) { session in
                            if let piece = pieces.first(where: { $0.id == session.pieceId }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(piece.title)
                                            .font(.body)
                                        Text(session.startTime.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if let duration = session.duration {
                                        Text(formatDuration(duration))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                
                // App Info Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(AppConstants.appVersion)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}