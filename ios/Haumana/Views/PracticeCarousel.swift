//
//  PracticeCarousel.swift
//  haumana
//
//  Created on 6/6/2025.
//

import SwiftUI

struct PracticeCarousel: View {
    let pieces: [Piece]
    @Binding var currentIndex: Int
    let onSelect: (Piece, Int) -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    private let cardSpacing: CGFloat = 20
    
    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width * 0.8
            let totalCardWidth = cardWidth + cardSpacing
            
            VStack(spacing: 0) {
                // Carousel cards
                ZStack {
                    ForEach(pieces.indices, id: \.self) { index in
                        PracticeCarouselCard(
                            piece: pieces[index],
                            isSelected: index == currentIndex,
                            onTap: {
                                onSelect(pieces[index], index)
                            }
                        )
                        .frame(width: cardWidth)
                        .offset(x: cardOffset(for: index, cardWidth: totalCardWidth, in: geometry))
                        .opacity(cardOpacity(for: index))
                        .zIndex(index == currentIndex ? 1 : 0)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height * 0.6)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Practice carousel")
                .accessibilityHint("Swipe left or right to browse pieces. Currently showing piece \(currentIndex + 1) of \(pieces.count)")
                .accessibilityValue("\(pieces[safe: currentIndex]?.title ?? "Unknown piece")")
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            
                            // Add resistance at the edges
                            if (currentIndex == 0 && value.translation.width > 0) ||
                               (currentIndex == pieces.count - 1 && value.translation.width < 0) {
                                // Apply rubber band effect at edges
                                let resistance: CGFloat = 0.3
                                dragOffset = value.translation.width * resistance
                            } else {
                                dragOffset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            isDragging = false
                            handleDragEnd(
                                translation: value.translation.width,
                                velocity: value.predictedEndTranslation.width - value.translation.width,
                                cardWidth: totalCardWidth
                            )
                        }
                )
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(pieces.indices, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? Color.accentColor : Color(.systemGray4))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentIndex ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: currentIndex)
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    currentIndex = index
                                    dragOffset = 0
                                    announceCurrentPiece()
                                }
                            }
                            .accessibilityLabel("Page \(index + 1) of \(pieces.count)")
                            .accessibilityAddTraits(index == currentIndex ? [.isSelected] : [])
                            .accessibilityHint("Tap to jump to this piece")
                    }
                }
                .padding(.top, 20)
                .accessibilityElement(children: .contain)
                
                // Navigation hints (show only when navigation is possible)
                if pieces.count > 1 {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .opacity(currentIndex > 0 ? 0.3 : 0)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .opacity(currentIndex < pieces.count - 1 ? 0.3 : 0)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
                }
            }
        }
    }
    
    private func cardOffset(for index: Int, cardWidth: CGFloat, in geometry: GeometryProxy) -> CGFloat {
        let indexDifference = CGFloat(index - currentIndex)
        let baseOffset = indexDifference * cardWidth
        
        // Center adjustment: when there's only one card or to ensure proper centering
        let centeringOffset: CGFloat = 0 // Cards are already centered by the ZStack
        
        return baseOffset + dragOffset + centeringOffset
    }
    
    private func cardOpacity(for index: Int) -> Double {
        let distance = abs(index - currentIndex)
        switch distance {
        case 0:
            return 1.0
        case 1:
            return 0.6
        default:
            return 0.3
        }
    }
    
    private func handleDragEnd(translation: CGFloat, velocity: CGFloat, cardWidth: CGFloat) {
        let threshold = cardWidth * 0.3
        let velocityThreshold: CGFloat = 500
        let previousIndex = currentIndex
        
        // Use gentler spring animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            // Check if we should change cards
            if abs(velocity) > velocityThreshold {
                // Fast swipe
                if velocity < 0 && currentIndex < pieces.count - 1 {
                    currentIndex += 1
                } else if velocity > 0 && currentIndex > 0 {
                    currentIndex -= 1
                }
                // No wrapping - just spring back if at edges
            } else if abs(translation) > threshold {
                // Slow drag past threshold
                if translation < 0 && currentIndex < pieces.count - 1 {
                    currentIndex += 1
                } else if translation > 0 && currentIndex > 0 {
                    currentIndex -= 1
                }
                // No wrapping - just spring back if at edges
            }
            
            // Always reset drag offset
            dragOffset = 0
        }
        
        // Announce change if index changed
        if currentIndex != previousIndex {
            announceCurrentPiece()
        }
    }
    
    private func announceCurrentPiece() {
        guard let piece = pieces[safe: currentIndex] else { return }
        let announcement = "Showing \(piece.title), piece \(currentIndex + 1) of \(pieces.count)"
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
}

// Safe array subscript extension
private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}

// Preview provider
struct PracticeCarousel_Previews: PreviewProvider {
    @State static var currentIndex = 0
    
    static var previews: some View {
        PracticeCarousel(
            pieces: [
                Piece(title: "Test Oli 1", category: .oli, lyrics: "Sample lyrics here...", language: "haw"),
                Piece(title: "Test Mele 1", category: .mele, lyrics: "Another sample...", language: "haw"),
                Piece(title: "Test Oli 2", category: .oli, lyrics: "More lyrics...", language: "haw")
            ],
            currentIndex: $currentIndex,
            onSelect: { _, _ in }
        )
        .frame(height: 500)
        .padding()
    }
}