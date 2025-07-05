//
//  OnboardingCoordinator.swift
//  haumana
//
//  Created on 7/2/2025.
//

import SwiftUI
import SwiftData

struct OnboardingCoordinator: View {
    @Environment(\.authService) private var authService
    @Environment(\.modelContext) private var modelContext
    
    @State private var onboardingStep: OnboardingStep = .signIn
    @State private var currentUser: User?
    @State private var birthdate: Date?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var parentEmail = ""
    @State private var consentService: ConsentService?
    
    enum OnboardingStep {
        case signIn
        case ageVerification
        case parentEmailCollection
        case waitingForParent
        case parentApproved
        case parentDenied
        case complete
    }
    
    var body: some View {
        ZStack {
            switch onboardingStep {
            case .signIn:
                SignInView()
                    .onChange(of: authService?.isSignedIn ?? false) { oldValue, newValue in
                        if newValue {
                            handleSignInComplete()
                        }
                    }
                
            case .ageVerification:
                AgeVerificationView(birthdate: $birthdate) { date in
                    handleAgeVerificationComplete(date)
                }
                
            case .parentEmailCollection:
                ParentEmailCollectionView { email in
                    handleParentEmailSubmit(email)
                }
                
            case .waitingForParent:
                SimplifiedWaitingForParentView(modelContext: modelContext) { approved in
                    if approved {
                        onboardingStep = .parentApproved
                    } else {
                        onboardingStep = .parentDenied
                    }
                }
                
            case .parentApproved:
                ConsentApprovedView {
                    onboardingStep = .complete
                }
                
            case .parentDenied:
                ConsentDeniedView(onSignOut: {
                    // Sign out and go back to sign in
                    Task {
                        await authService?.signOut()
                        onboardingStep = .signIn
                    }
                })
                
            case .complete:
                MainTabView()
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Check if user is already signed in
            if authService?.isSignedIn == true {
                handleSignInComplete()
            }
        }
    }
    
    private func handleSignInComplete() {
        guard let authService = authService,
              let user = authService.currentUser else {
            return
        }
        
        currentUser = user
        
        // Check if we already have birthdate stored
        do {
            if let storedBirthdate = try KeychainService.shared.getBirthdate(for: user.id) {
                // Update user model
                user.birthdate = storedBirthdate
                user.isMinor = isUserMinor(birthdate: storedBirthdate)
                
                // If minor, check consent status
                if user.isMinor {
                    checkParentConsentStatus()
                } else {
                    onboardingStep = .complete
                }
            } else {
                // New user or no birthdate stored
                onboardingStep = .ageVerification
            }
        } catch {
            errorMessage = "Error retrieving user data: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func handleAgeVerificationComplete(_ date: Date) {
        guard let user = currentUser else { return }
        
        // Save birthdate securely
        do {
            try KeychainService.shared.saveBirthdate(date, for: user.id)
            
            // Update user model
            user.birthdate = date
            user.isMinor = isUserMinor(birthdate: date)
            
            // Save to database
            try modelContext.save()
            
            // Check if user is a minor
            if user.isMinor {
                checkParentConsentStatus()
            } else {
                onboardingStep = .complete
            }
        } catch {
            errorMessage = "Error saving user information: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func checkParentConsentStatus() {
        guard let user = currentUser else { return }
        
        // Check if we already have parent consent
        if let consentStatus = user.parentConsentStatus,
           let status = ParentConsentStatus(rawValue: consentStatus) {
            switch status {
            case .approved:
                // Already approved, proceed to main app
                onboardingStep = .complete
            case .denied:
                // Allow them to try again with a different parent email
                onboardingStep = .parentEmailCollection
            case .pending:
                // Check DynamoDB for updated status
                checkConsentStatusFromAPI(user: user)
            }
        } else {
            // No consent status yet, need to collect parent email
            onboardingStep = .parentEmailCollection
        }
    }
    
    private func checkConsentStatusFromAPI(user: User) {
        // Create ConsentService to check status
        let consentService = ConsentService(modelContext: modelContext)
        
        Task {
            await consentService.checkConsentStatus(for: user)
            
            await MainActor.run {
                // Check the updated status
                if let updatedStatus = user.parentConsentStatus,
                   let status = ParentConsentStatus(rawValue: updatedStatus) {
                    switch status {
                    case .approved:
                        onboardingStep = .complete
                    case .denied:
                        // Allow them to try again with a different parent email
                        onboardingStep = .parentEmailCollection
                    case .pending:
                        // Still pending, show waiting view
                        onboardingStep = .waitingForParent
                    }
                } else {
                    // No status found, show email collection
                    onboardingStep = .parentEmailCollection
                }
            }
        }
    }
    
    private func isUserMinor(birthdate: Date) -> Bool {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthdate, to: Date())
        return (ageComponents.year ?? 0) < 13
    }
    
    private func handleParentEmailSubmit(_ email: String) {
        guard let user = currentUser else { return }
        
        parentEmail = email
        
        // Initialize consent service if needed
        if consentService == nil {
            consentService = ConsentService(modelContext: modelContext)
        }
        
        Task {
            do {
                // Request parent consent
                try await consentService?.requestParentConsent(for: user, parentEmail: email)
                
                await MainActor.run {
                    // Move to waiting state
                    onboardingStep = .waitingForParent
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

#Preview {
    OnboardingCoordinator()
}