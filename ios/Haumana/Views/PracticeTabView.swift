//
//  PracticeTabView.swift
//  haumana
//
//  Created on 6/3/2025.
//

import SwiftUI
import SwiftData

struct PracticeTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var pieces: [Piece]
    @Query private var recentSessions: [PracticeSession]
    
    private var practiceEligibleCount: Int {
        pieces.filter { $0.includeInPractice }.count
    }
    
    private var lastPracticedPiece: Piece? {
        guard let lastSession = recentSessions.first else { return nil }
        return pieces.first { $0.id == lastSession.pieceId }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Stats Section
                HStack(spacing: 32) {
                    StatView(title: "Streak", value: "0", unit: "days")
                    StatView(title: "Total", value: "\(pieces.count)", unit: "pieces")
                    StatView(title: "Available", value: "\(practiceEligibleCount)", unit: "to practice")
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Last Practiced Section
                if let lastPiece = lastPracticedPiece {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last Practiced")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(lastPiece.title)
                                    .font(.title3)
                                    .fontWeight(.medium)
                                Text(lastPiece.categoryEnum.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if let lastPracticed = lastPiece.lastPracticed {
                                Text(lastPracticed.formatted(.relative(presentation: .named)))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Start Practice Button
                if practiceEligibleCount > 0 {
                    Button(action: {
                        // TODO: Start practice session
                    }) {
                        Label("Start Practice", systemImage: "play.circle.fill")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.accentColor)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 32)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No pieces available for practice")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Add pieces to your repertoire to start practicing")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Practice")
        }
    }
}

struct StatView: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.largeTitle)
                .fontWeight(.bold)
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}