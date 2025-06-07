//
//  PracticeScreenView.swift
//  haumana
//
//  Created on 6/3/2025.
//

import SwiftUI

struct PracticeScreenView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Bindable var viewModel: PracticeViewModel
    @State private var showingTranslation = false
    @State private var showingDetails = false
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var showSwipeHint = true
    @AppStorage("hasSeenPracticeSwipeHint") private var hasSeenPracticeSwipeHint = false
    
    var body: some View {
        NavigationStack {
            if let piece = viewModel.currentPiece {
                GeometryReader { geometry in
                    ZStack {
                        // Exit gesture hint (right edge)
                        HStack {
                            Spacer()
                            
                            Rectangle()
                                .fill(Color.accentColor.opacity(0.2))
                                .frame(width: 80)
                                .overlay(
                                    HStack(spacing: 4) {
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                        Text("Swipe to finish")
                                            .font(.caption2)
                                    }
                                    .foregroundColor(.accentColor)
                                    .rotationEffect(.degrees(-90))
                                )
                        }
                        .opacity(showSwipeHint && isDragging && dragOffset > 20 ? Double(dragOffset) / 100 : 0)
                        
                        // Main content
                        VStack(spacing: 0) {
                            // Header
                            PracticeHeaderView(piece: piece, viewModel: viewModel)
                                .padding()
                            
                            Divider()
                            
                            // Lyrics content
                            if verticalSizeClass == .compact {
                                // Landscape side-by-side view
                                LandscapeLyricsView(
                                    piece: piece,
                                    showingTranslation: $showingTranslation
                                )
                            } else {
                                // Portrait stacked view
                                PortraitLyricsView(
                                    piece: piece,
                                    showingTranslation: $showingTranslation
                                )
                            }
                        }
                        .background(Color(.systemBackground))
                        .offset(x: dragOffset)
                        .gesture(exitGesture)
                        .accessibilityAction(.escape) {
                            // Allow VoiceOver users to exit with escape gesture
                            Task {
                                await viewModel.endPractice()
                                dismiss()
                            }
                        }
                        
                        // Initial swipe hint on right edge
                        if showSwipeHint && !isDragging && !hasSeenPracticeSwipeHint {
                            HStack {
                                Spacer()
                                
                                VStack {
                                    Spacer()
                                    HStack(spacing: 2) {
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .opacity(0.6)
                                    }
                                    .foregroundColor(.accentColor)
                                    .padding(8)
                                    .background(
                                        Capsule()
                                            .fill(Color.accentColor.opacity(0.15))
                                    )
                                    Spacer()
                                }
                            }
                            .padding(.trailing, 8)
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                            .onAppear {
                                // Auto-hide hint after 5 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                    withAnimation {
                                        showSwipeHint = false
                                        hasSeenPracticeSwipeHint = true
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .task {
                    // Start the practice session when the screen appears
                    await viewModel.beginSelectedPractice()
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Details") {
                            showingDetails = true
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            Task {
                                await viewModel.endPractice()
                                dismiss()
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .sheet(isPresented: $showingDetails) {
                    if let piece = viewModel.currentPiece {
                        NavigationStack {
                            PieceDetailView(piece: piece)
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarTrailing) {
                                        Button("Done") {
                                            showingDetails = false
                                        }
                                    }
                                }
                        }
                    }
                }
            } else {
                ProgressView("Loading...")
            }
        }
    }
    
    private var exitGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Only respond to right swipes
                if value.translation.width > 0 {
                    isDragging = true
                    dragOffset = value.translation.width
                }
            }
            .onEnded { value in
                isDragging = false
                
                let threshold: CGFloat = 100
                
                if value.translation.width > threshold {
                    // Swipe right - end practice
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    // Hide hint after first successful swipe
                    showSwipeHint = false
                    hasSeenPracticeSwipeHint = true
                    
                    withAnimation(.spring()) {
                        dragOffset = UIScreen.main.bounds.width
                    }
                    
                    Task {
                        await viewModel.endPractice()
                        dismiss()
                    }
                } else {
                    // Spring back
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                }
            }
    }
}

struct PracticeHeaderView: View {
    let piece: Piece
    @Bindable var viewModel: PracticeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(piece.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .accessibilityAddTraits(.isHeader)
                    
                    HStack {
                        Label(piece.categoryEnum.displayName, systemImage: "music.note")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                        
                        Label(piece.displayLanguage, systemImage: "globe")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    Task {
                        await viewModel.toggleFavorite()
                    }
                }) {
                    Image(systemName: piece.isFavorite ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundColor(piece.isFavorite ? .yellow : .gray)
                        .scaleEffect(piece.isFavorite ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: piece.isFavorite)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(piece.isFavorite ? "Remove from favorites" : "Add to favorites")
                .accessibilityHint("Double tap to toggle favorite status")
            }
        }
        .accessibilityElement(children: .contain)
    }
}

struct PortraitLyricsView: View {
    let piece: Piece
    @Binding var showingTranslation: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Original lyrics
                Text(piece.lyrics)
                    .font(.body)
                    .padding()
                
                // Translation section
                if let translation = piece.englishTranslation, !translation.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: {
                            withAnimation {
                                showingTranslation.toggle()
                            }
                        }) {
                            HStack {
                                Text(showingTranslation ? "Hide Translation" : "Show Translation")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Image(systemName: showingTranslation ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                            }
                            .foregroundColor(.accentColor)
                        }
                        .padding(.horizontal)
                        
                        if showingTranslation {
                            Text(translation)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .padding(.horizontal)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

struct LandscapeLyricsView: View {
    let piece: Piece
    @Binding var showingTranslation: Bool
    
    var body: some View {
        ZStack {
            // Content
            if showingTranslation, let translation = piece.englishTranslation, !translation.isEmpty {
                LineAlignedLyricsView(
                    originalText: piece.lyrics,
                    translationText: translation
                )
            } else {
                // Original only - no grey background
                ScrollView {
                    Text(piece.lyrics)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if showingTranslation && piece.englishTranslation != nil {
                Button(action: {
                    withAnimation {
                        showingTranslation = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .background(Circle().fill(Color(.systemBackground)))
                }
                .padding()
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if !showingTranslation && piece.englishTranslation != nil {
                Button(action: {
                    withAnimation {
                        showingTranslation = true
                    }
                }) {
                    Label("Show Translation", systemImage: "globe")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
                .padding()
            }
        }
    }
}