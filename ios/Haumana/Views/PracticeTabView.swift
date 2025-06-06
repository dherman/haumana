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
            VStack(spacing: 0) {
                // Carousel Container - Takes 60% of vertical space
                if let vm = viewModel {
                    if vm.practiceEligibleCount > 0 {
                        GeometryReader { geometry in
                            VStack {
                                // Carousel placeholder - will be replaced with actual carousel
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemGray6))
                                    .frame(height: geometry.size.height * 0.6)
                                    .overlay(
                                        VStack(spacing: 16) {
                                            Image(systemName: "rectangle.stack.fill")
                                                .font(.system(size: 48))
                                                .foregroundColor(.secondary)
                                            Text("Carousel Coming Soon")
                                                .font(.headline)
                                                .foregroundColor(.secondary)
                                            Text("Swipe to browse pieces")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    )
                                    .padding(.horizontal)
                                
                                // Visual swipe indicators (dots)
                                HStack(spacing: 8) {
                                    ForEach(0..<5) { index in
                                        Circle()
                                            .fill(index == 2 ? Color.accentColor : Color(.systemGray4))
                                            .frame(width: 8, height: 8)
                                    }
                                }
                                .padding(.top, 12)
                                
                                Spacer()
                            }
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        // Empty state
                        Spacer()
                        EmptyPracticeView()
                        Spacer()
                    }
                } else {
                    // Loading state
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
                
                // Stats Section - Below carousel
                if let vm = viewModel {
                    VStack(spacing: 16) {
                        Divider()
                        
                        HStack(spacing: 32) {
                            StatView(title: "Streak", value: "\(vm.currentStreak)", unit: "days")
                            StatView(title: "Total", value: "\(vm.totalPieces)", unit: "pieces")
                            StatView(title: "Available", value: "\(vm.practiceEligibleCount)", unit: "to practice")
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
            .navigationTitle("Practice")
            .fullScreenCover(isPresented: $showingPracticeScreen) {
                if let vm = viewModel, vm.currentPiece != nil {
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