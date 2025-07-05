//
//  MainTabView.swift
//  haumana
//
//  Created on 6/3/2025.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.authService) private var authService
    @State private var selectedTab = 0
    @State private var showingOnboarding = false
    @Query private var pieces: [Piece]
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PracticeTabView()
                .tabItem {
                    Label("Practice", systemImage: "music.note.list")
                }
                .tag(0)
            
            RepertoireListView()
                .tabItem {
                    Label("Repertoire", systemImage: "square.text.square.fill")
                }
                .tag(1)
            
            ProfileTabView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(2)
        }
        .onAppear {
            // Check if user is signed in
            if authService?.isSignedIn != true {
                showingOnboarding = true
                return
            }
            
            // If user just signed in and has no pieces, show Repertoire tab
            if let authService = authService,
               let userId = authService.currentUser?.id {
                let userPieces = pieces.filter { $0.userId == userId }
                if userPieces.isEmpty {
                    selectedTab = 1
                }
            }
        }
        .onChange(of: authService?.isSignedIn) { _, isSignedIn in
            // Monitor sign-in status changes
            if isSignedIn != true {
                showingOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingCoordinator()
        }
    }
}