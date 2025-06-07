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
    @State private var viewModel: ProfileViewModel?
    
    // Use @Query to observe session changes
    @Query(sort: \PracticeSession.startTime, order: .reverse) private var sessions: [PracticeSession]
    @Query private var pieces: [Piece]
    
    var body: some View {
        NavigationStack {
            if let viewModel = viewModel {
                profileContent(viewModel: viewModel)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            if viewModel == nil {
                viewModel = ProfileViewModel(modelContext: modelContext)
                await viewModel?.loadProfileData()
            }
        }
        .onChange(of: sessions.count) { _, _ in
            // Reload data when sessions change
            Task {
                await viewModel?.loadProfileData()
            }
        }
    }
    
    @ViewBuilder
    private func profileContent(viewModel: ProfileViewModel) -> some View {
        List {
                // User Section
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.userName)
                                .font(.headline)
                            Text(viewModel.userEmail)
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
                        Text("\(viewModel.currentStreak) days")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Total Sessions", systemImage: "music.note")
                        Spacer()
                        Text("\(viewModel.totalSessions)")
                            .foregroundColor(.secondary)
                    }
                    
                    if let mostPracticed = viewModel.mostPracticedPiece {
                        HStack {
                            Label("Most Practiced", systemImage: "star")
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(mostPracticed.title)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                Text("\(viewModel.mostPracticedCount) times")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Recent Practice History
                if !viewModel.recentSessions.isEmpty {
                    Section("Recent Practice") {
                        ForEach(viewModel.recentSessions) { sessionWithPiece in
                            NavigationLink(destination: PieceDetailView(piece: sessionWithPiece.piece)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(sessionWithPiece.piece.title)
                                            .font(.body)
                                        Text(viewModel.formatSessionDate(sessionWithPiece.session.startTime))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(viewModel.formatSessionDuration(sessionWithPiece.session))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                
                // Help Section
                Section("How to Use") {
                    NavigationLink(destination: HelpView()) {
                        Label("Practice Guide", systemImage: "questionmark.circle")
                    }
                }
                
                // App Info Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com/dherman/haumana")!) {
                        HStack {
                            Text("View on GitHub")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .refreshable {
                await viewModel.refresh()
            }
            .onAppear {
                // Refresh when tab becomes visible
                Task {
                    await viewModel.loadProfileData()
                }
            }
    }
}