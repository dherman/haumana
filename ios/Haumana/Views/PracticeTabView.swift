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
    @State private var viewModel: PracticeViewModel?
    @State private var showingPracticeScreen = false
    @Query(sort: \PracticeSession.startTime, order: .reverse) private var recentSessions: [PracticeSession]
    @Query private var pieces: [Piece]
    
    private var lastPracticedPiece: Piece? {
        guard let lastSession = recentSessions.first else { return nil }
        return pieces.first { $0.id == lastSession.pieceId }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Stats Section
                if let vm = viewModel {
                    HStack(spacing: 32) {
                        StatView(title: "Streak", value: "\(vm.currentStreak)", unit: "days")
                        StatView(title: "Total", value: "\(vm.totalPieces)", unit: "pieces")
                        StatView(title: "Available", value: "\(vm.practiceEligibleCount)", unit: "to practice")
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
                
                // Last Practiced Section
                if let lastPiece = lastPracticedPiece {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last Practiced")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            Task {
                                await viewModel?.startSessionForSpecificPiece(lastPiece)
                                showingPracticeScreen = true
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(lastPiece.title)
                                        .font(.title3)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
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
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Start Practice Button
                if let vm = viewModel {
                    if vm.practiceEligibleCount > 0 {
                        Button(action: {
                            // Add haptic feedback
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            
                            Task {
                                await vm.startPracticeSession()
                                if vm.currentPiece != nil {
                                    showingPracticeScreen = true
                                }
                            }
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
                        .disabled(vm.isLoading)
                        
                        if let error = vm.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                    } else {
                        EmptyPracticeView()
                    }
                } else {
                    ProgressView()
                        .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Practice")
            .fullScreenCover(isPresented: $showingPracticeScreen) {
                if let vm = viewModel, let piece = vm.currentPiece {
                    PracticeScreenView(viewModel: vm)
                }
            }
        }
        .task {
            if viewModel == nil {
                viewModel = PracticeViewModel(modelContext: modelContext)
            }
            await viewModel?.loadStatistics()
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

struct EmptyPracticeView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .symbolEffect(.pulse, options: .repeating)
            
            Text("No pieces available for practice")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Add pieces to your repertoire\nor enable them for practice")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Add navigation hint
            Text("Go to the Repertoire tab to get started")
                .font(.caption)
                .foregroundColor(.accentColor)
                .padding(.top, 8)
        }
        .padding()
    }
}