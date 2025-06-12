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
    @State private var authViewModel: AuthenticationViewModel?
    
    // Use @Query to observe changes
    @Query(sort: \PracticeSession.startTime, order: .reverse) private var sessions: [PracticeSession]
    @Query private var pieces: [Piece]
    
    // Computed stats for unauthenticated view
    private var localPiecesCount: Int {
        pieces.filter { $0.userId == nil }.count
    }
    
    private var localSessionsCount: Int {
        sessions.filter { $0.userId == nil }.count
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let authViewModel = authViewModel,
                   let profileViewModel = profileViewModel {
                    profileContent(
                        authViewModel: authViewModel,
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
            if authViewModel == nil, let authService = authService {
                authViewModel = AuthenticationViewModel(authService: authService)
            }
            
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
            isPresented: .init(
                get: { authViewModel?.showingSignOutConfirmation ?? false },
                set: { authViewModel?.showingSignOutConfirmation = $0 }
            ),
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                authViewModel?.confirmSignOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out? Your data will remain on this device.")
        }
        .alert(
            "Error",
            isPresented: .init(
                get: { authViewModel?.errorMessage != nil },
                set: { if !$0 { authViewModel?.errorMessage = nil } }
            ),
            presenting: authViewModel?.errorMessage
        ) { _ in
            Button("OK") {
                authViewModel?.errorMessage = nil
            }
        } message: { error in
            Text(error)
        }
    }
    
    @ViewBuilder
    private func profileContent(
        authViewModel: AuthenticationViewModel,
        profileViewModel: ProfileViewModel
    ) -> some View {
        List {
            if authViewModel.isSignedIn,
               let user = authViewModel.user {
                // Authenticated view sections
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
                        authViewModel.signOut()
                    }
                )
            } else {
                // Unauthenticated view sections
                UnauthenticatedProfileView(
                    onSignIn: {
                        await authViewModel.signIn()
                    },
                    totalLocalPieces: localPiecesCount,
                    totalLocalSessions: localSessionsCount
                )
            }
            
            // Common footer sections
            ProfileFooterView(appVersion: profileViewModel.appVersion)
        }
        .refreshable {
            if authViewModel.isSignedIn {
                await profileViewModel.refresh()
            }
        }
    }
}