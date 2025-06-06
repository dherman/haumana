//
//  HelpView.swift
//  haumana
//
//  Created on 6/6/2025.
//

import SwiftUI

struct HelpView: View {
    var body: some View {
        List {
            // Getting Started Section
            Section("Getting Started") {
                HelpItem(
                    icon: "music.note.list",
                    title: "Add Pieces",
                    description: "Go to the Repertoire tab and tap the + button to add oli (chants) or mele (songs) to your collection."
                )
                
                HelpItem(
                    icon: "star",
                    title: "Mark Favorites",
                    description: "Tap the star icon on any piece to mark it as a favorite. Favorites are prioritized during practice sessions."
                )
                
                HelpItem(
                    icon: "toggle.on",
                    title: "Enable for Practice",
                    description: "In piece details, toggle \"Include in Practice\" to control which pieces appear during practice sessions."
                )
            }
            
            // Practice Mode Section
            Section("Practice Mode") {
                HelpItem(
                    icon: "hand.draw",
                    title: "Browse with Carousel",
                    description: "On the Practice tab, swipe left or right through the carousel to browse suggested pieces before starting practice."
                )
                
                HelpItem(
                    icon: "play.circle",
                    title: "Start Practice",
                    description: "Tap on any piece in the carousel to begin practicing it. The practice screen will open automatically."
                )
                
                HelpItem(
                    icon: "arrow.right.circle",
                    title: "Finish Practice",
                    description: "During practice, swipe right from anywhere on the screen to finish and return to the Practice tab."
                )
            }
            
            // Features Section
            Section("Features") {
                HelpItem(
                    icon: "globe",
                    title: "View Translations",
                    description: "If a piece has an English translation, tap \"Show Translation\" to view it side-by-side with the original text."
                )
                
                HelpItem(
                    icon: "magnifyingglass",
                    title: "Search Repertoire",
                    description: "Use the search bar in the Repertoire tab to quickly find pieces by title, lyrics, or author."
                )
                
                HelpItem(
                    icon: "chart.bar",
                    title: "Track Progress",
                    description: "The Profile tab shows your practice streak, total sessions, and most practiced pieces."
                )
            }
            
            // Tips Section
            Section("Tips") {
                HelpItem(
                    icon: "lightbulb",
                    title: "Practice Algorithm",
                    description: "The app prioritizes pieces you haven't practiced recently, especially favorites that haven't been practiced in over 7 days."
                )
                
                HelpItem(
                    icon: "timer",
                    title: "Session Tracking",
                    description: "Practice sessions are automatically tracked from when you open a piece until you swipe to finish."
                )
                
                HelpItem(
                    icon: "arrow.clockwise",
                    title: "Refresh Data",
                    description: "Pull down to refresh on any list view to update the displayed information."
                )
            }
        }
        .navigationTitle("Practice Guide")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct HelpItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        HelpView()
    }
}