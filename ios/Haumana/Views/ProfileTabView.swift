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
    @Environment(\.authService) private var authService
    
    @State private var profileViewModel: ProfileViewModel?
    @State private var showingSignOutConfirmation = false
    @State private var errorMessage: String?
    
    // Use @Query to observe changes
    @Query(sort: \PracticeSession.startTime, order: .reverse) private var sessions: [PracticeSession]
    
    var body: some View {
        NavigationStack {
            Group {
                if let profileViewModel = profileViewModel,
                   let authService = authService {
                    profileContent(
                        authService: authService,
                        profileViewModel: profileViewModel
                    )
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Profile")
        }
        .task {
            if profileViewModel == nil, let authService = authService {
                profileViewModel = ProfileViewModel(
                    modelContext: modelContext,
                    authService: authService
                )
                await profileViewModel?.loadProfileData()
            }
        }
        .onChange(of: sessions.count) { _, _ in
            // Reload data when sessions change
            Task {
                await profileViewModel?.loadProfileData()
            }
        }
        .confirmationDialog(
            "Sign Out",
            isPresented: $showingSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                Task {
                    await authService?.signOut()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out? Your data will remain on this device.")
        }
        .alert(
            "Error",
            isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            ),
            presenting: errorMessage
        ) { _ in
            Button("OK") {
                errorMessage = nil
            }
        } message: { error in
            Text(error)
        }
    }
    
    @ViewBuilder
    private func profileContent(
        authService: AuthenticationServiceProtocol,
        profileViewModel: ProfileViewModel
    ) -> some View {
        List {
            // User is always authenticated when viewing Profile tab
            if let user = authService.currentUser {
                AuthenticatedProfileView(
                    user: user,
                    profileStats: AuthenticatedProfileView.ProfileStats(
                        currentStreak: profileViewModel.currentStreak,
                        totalSessions: profileViewModel.totalSessions,
                        mostPracticedPiece: profileViewModel.mostPracticedPiece,
                        mostPracticedCount: profileViewModel.mostPracticedCount
                    ),
                    recentSessions: profileViewModel.recentSessions,
                    onSignOut: {
                        showingSignOutConfirmation = true
                    }
                )
            }
            
            // Common footer sections
            ProfileFooterView(appVersion: profileViewModel.appVersion)
        }
        .refreshable {
            await profileViewModel.refresh()
        }
    }
}