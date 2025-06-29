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
                            .background(piece.categoryEnum == .oli ? AppConstants.oliColor : AppConstants.meleColor)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(piece.title), \(piece.categoryEnum.displayName)\(piece.isFavorite ? ", Favorite" : "")")
        .accessibilityHint("Double tap to practice this piece")
        .accessibilityAddTraits(.isButton)
    }
}

// Preview provider for SwiftUI previews
struct PracticeCarouselCard_Previews: PreviewProvider {
    static var previews: some View {
        PracticeCarouselCard(
            piece: Piece(
                title: "E Kuʻu Morning Dew",
                category: .mele,
                lyrics: "E kuʻu morning dew\nAlia mai, alia mai\nMaliu mai ʻoe\nI kaʻu e hea nei\nE kali mai ʻoe\nIaʻu nei, iaʻu nei\nʻO wau iho nō\nMe ke aloha\n \nWehe mai ke alaula\nʻOliliko nei līhau\nE hoʻohehelo ana\nI neia papālina\nI uka o Mānā\nI ka ʻiu uhiwai\nMa laila nō kāua\nE pili mau ai\nMa laila nō kāua\nE pili mau ai",
                language: "haw",
                author: "Eddie Kamae"
            ),
            isSelected: true,
            onTap: {}
        )
        .frame(height: 400)
        .padding()
    }
}

