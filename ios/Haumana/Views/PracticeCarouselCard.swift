//
//  PracticeCarouselCard.swift
//  haumana
//
//  Created on 6/6/2025.
//

import SwiftUI

struct PracticeCarouselCard: View {
    let piece: Piece
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 16) {
                // Header with title and category
                VStack(alignment: .leading, spacing: 8) {
                    Text(piece.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Label(piece.categoryEnum.displayName, systemImage: piece.categoryEnum == .oli ? "music.note" : "music.note.list")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(piece.categoryEnum == .oli ? Color.blue : Color.purple)
                            .cornerRadius(20)
                        
                        Spacer()
                        
                        if piece.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                }
                
                Divider()
                    .background(Color(.systemGray4))
                
                // Lyrics preview
                Text(piece.lyrics)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Tap hint at bottom
                HStack {
                    Spacer()
                    Text("Tap to practice")
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                        .opacity(isSelected ? 1 : 0.6)
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                        .opacity(isSelected ? 1 : 0.6)
                }
            }
            .padding(24)
            .frame(width: geometry.size.width * 0.8)
            .frame(maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                
                // Haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                    onTap()
                }
            }
        }
    }
}

// Preview provider for SwiftUI previews
struct PracticeCarouselCard_Previews: PreviewProvider {
    static var previews: some View {
        PracticeCarouselCard(
            piece: Piece(
                title: "E Kuʻu Morning Dew",
                category: .oli,
                lyrics: "E kuʻu morning dew\nKa wai ʻawaʻawa\nHoʻokahi ka manaʻo\nAloha wau iā ʻoe\n\nNa ka makani e pā mai\nMe he ʻala pua mae\nʻAʻole naʻe he mea ʻē\nI kuʻu aloha ʻole ʻoe",
                language: "haw"
            ),
            isSelected: true,
            onTap: {}
        )
        .frame(height: 400)
        .padding()
    }
}