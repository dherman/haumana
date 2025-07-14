//
//  ProfileTabView.swift
//  haumana
//
//  Created on 6/3/2025.
//

import SwiftUI
import SwiftData

extension URL: Identifiable {
    public var id: String { absoluteString }
}

struct ProfileTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.authService) private var authService
    @Environment(\.syncService) private var syncService
    
    @State private var profileViewModel: ProfileViewModel?
    @State private var showingSignOutConfirmation = false
    @State private var errorMessage: String?
    @State private var exportFileURL: URL?
    @State private var isExportingData = false
    @State private var showingExportError = false
    @State private var exportError: String?
    
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
        .sheet(item: $exportFileURL) { url in
            ShareSheet(activityItems: [url])
        }
        .alert("Export Error", isPresented: $showingExportError, presenting: exportError) { _ in
            Button("OK") {
                exportError = nil
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
            
            // Test mode controls
            #if DEBUG
            if profileViewModel.isInTestMode {
                Section("🧪 Test Mode - Parental Consent") {
                    if let user = authService.currentUser,
                       user.isMinor,
                       let status = user.parentConsentStatus {
                        Text("Current Status: \(status)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Simulate Parent Approval") {
                            Task {
                                await profileViewModel.simulateParentApproval()
                            }
                        }
                        .foregroundColor(.green)
                        
                        Button("Simulate Parent Denial") {
                            Task {
                                await profileViewModel.simulateParentDenial()
                            }
                        }
                        .foregroundColor(.red)
                    } else {
                        Text("Test mode active - Sign in as a minor to test consent")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            #endif
            
            // Common footer sections
            ProfileFooterView(
                appVersion: profileViewModel.appVersion,
                onExportData: exportData,
                isExportingData: isExportingData
            )
        }
        .refreshable {
            await profileViewModel.refresh()
        }
    }
    
    private func exportData() {
        guard let authService = authService else { return }
        
        isExportingData = true
        
        Task {
            do {
                let privacyService = PrivacyService(authService: authService)
                let exportData = try await privacyService.exportUserData()
                
                // Create file in temporary directory
                let fileName = "haumana-export-\(Int(Date().timeIntervalSince1970)).json"
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                try exportData.write(to: tempURL)
                
                await MainActor.run {
                    isExportingData = false
                    exportFileURL = tempURL
                }
            } catch {
                await MainActor.run {
                    isExportingData = false
                    exportError = error.localizedDescription
                    showingExportError = true
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        controller.excludedActivityTypes = [.assignToContact, .saveToCameraRoll, .addToReadingList]
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}