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
    @State private var showCarouselTooltip = false
    @AppStorage("hasSeenCarouselTooltip") private var hasSeenCarouselTooltip = false
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
                    if vm.practiceEligibleCount > 0 && !vm.suggestionQueue.isEmpty {
                        PracticeCarouselWrapper(viewModel: vm) { piece, index in
                            Task {
                                await vm.selectPieceFromCarousel(at: index)
                                showingPracticeScreen = true
                            }
                        }
                        .overlay(alignment: .top) {
                            if showCarouselTooltip {
                                TooltipView(text: "Swipe to browse pieces")
                                    .padding(.top, 16)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                    .onAppear {
                                        // Auto-dismiss after 5 seconds
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                            withAnimation {
                                                showCarouselTooltip = false
                                                hasSeenCarouselTooltip = true
                                            }
                                        }
                                    }
                                    .onTapGesture {
                                        withAnimation {
                                            showCarouselTooltip = false
                                            hasSeenCarouselTooltip = true
                                        }
                                    }
                            }
                        }
                    } else if vm.practiceEligibleCount > 0 && vm.suggestionQueue.isEmpty {
                        // Loading suggestions
                        Spacer()
                        VStack(spacing: 16) {
                            ProgressView()
                            Text("Loading suggestions...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
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
            .fullScreenCover(isPresented: $showingPracticeScreen, onDismiss: {
                Task {
                    await viewModel?.updateCarouselAfterPractice()
                }
            }) {
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
            
            // Show tooltip on first launch if we have eligible pieces
            if !hasSeenCarouselTooltip && viewModel?.practiceEligibleCount ?? 0 > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        showCarouselTooltip = true
                    }
                }
            }
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

struct PracticeCarouselWrapper: View {
    let viewModel: PracticeViewModel
    let onSelect: (Piece, Int) -> Void
    
    var body: some View {
        PracticeCarousel(
            pieces: viewModel.suggestionQueue,
            currentIndex: Binding(
                get: { viewModel.currentCarouselIndex },
                set: { viewModel.currentCarouselIndex = $0 }
            ),
            onSelect: onSelect
        )
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

struct TooltipView: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.draw")
                .font(.caption)
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.accentColor)
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        )
    }
}