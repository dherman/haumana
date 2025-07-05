//
//  WaitingForParentView.swift
//  haumana
//
//  Created on 7/3/2025.
//

import SwiftUI
import SwiftData

struct WaitingForParentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.authService) private var authService
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var consentService: ConsentService
    
    @State private var checkTimer: Timer?
    @State private var showingApprovedView = false
    @State private var showingDeniedView = false
    
    let onCompletion: (Bool) -> Void // true if approved, false if denied
    
    init(modelContext: ModelContext, onCompletion: @escaping (Bool) -> Void = { _ in }) {
        _consentService = StateObject(wrappedValue: ConsentService(modelContext: modelContext))
        self.onCompletion = onCompletion
    }
    
    var body: some View {
        ZStack {
            // Lehua red background to match other screens
            Color.lehuaRed
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Animated waiting icon
                Image(systemName: "envelope.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.white)
                    .symbolEffect(.pulse)
                
                // Status text
                Text("Waiting for Parent Approval")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("We've sent an email to your parent.\nAs soon as we get their permission, you can get started!")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // Parent email
                if let parentEmail = authService?.currentUser?.parentEmail {
                    Text("Email sent to: \(parentEmail)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 10)
                }
                
                Spacer()
                
                // Manual refresh button
                Button(action: checkStatus) {
                    HStack {
                        if consentService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(consentService.isLoading ? "Checking..." : "Check Status")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(consentService.isLoading ? .white.opacity(0.6) : .white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white, lineWidth: 2)
                    )
                }
                .disabled(consentService.isLoading)
                
                // Sign out option
                Button(action: signOut) {
                    Text("Sign Out")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .underline()
                }
                
                // Test mode controls
                #if DEBUG
                if KWSAPIClient.shared.isTestMode {
                    VStack(spacing: 12) {
                        Text("🧪 Test Mode")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack(spacing: 20) {
                            Button(action: simulateApproval) {
                                Text("Simulate Approval")
                                    .font(.system(size: 14))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color.white)
                                    )
                            }
                            
                            Button(action: simulateDenial) {
                                Text("Simulate Denial")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color.white)
                                    )
                            }
                        }
                    }
                    .padding(.top, 20)
                }
                #endif
                
                Spacer()
                    .frame(height: 50)
            }
        }
        .onAppear {
            startPolling()
        }
        .onDisappear {
            stopPolling()
        }
        .fullScreenCover(isPresented: $showingApprovedView) {
            ConsentApprovedView {
                // Notify parent view and dismiss
                showingApprovedView = false
                onCompletion(true)
                dismiss()
            }
        }
        .fullScreenCover(isPresented: $showingDeniedView) {
            ConsentDeniedView {
                Task {
                    await authService?.signOut()
                    showingDeniedView = false
                    dismiss()
                }
            }
        }
    }
    
    private func startPolling() {
        // Check immediately
        checkStatus()
        
        // Then check every 30 seconds
        checkTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            checkStatus()
        }
    }
    
    private func stopPolling() {
        checkTimer?.invalidate()
        checkTimer = nil
    }
    
    private func checkStatus() {
        guard let user = authService?.currentUser else { return }
        
        Task {
            await consentService.checkConsentStatus(for: user)
            
            await MainActor.run {
                switch consentService.consentStatus {
                case .approved:
                    stopPolling()
                    showingApprovedView = true
                case .denied:
                    stopPolling()
                    showingDeniedView = true
                case .pending:
                    // Keep waiting
                    break
                }
            }
        }
    }
    
    private func signOut() {
        Task {
            await authService?.signOut()
            dismiss()
        }
    }
    
    #if DEBUG
    private func simulateApproval() {
        guard let user = authService?.currentUser else { return }
        
        // Update user's consent status
        user.parentConsentStatus = ParentConsentStatus.approved.rawValue
        user.parentConsentDate = Date()
        
        // Save changes
        do {
            try modelContext.save()
            
            // Force modelContext to process the change
            modelContext.processPendingChanges()
            
            // Trigger the UI update
            stopPolling()
            showingApprovedView = true
        } catch {
            print("Error saving approval: \(error)")
        }
    }
    
    private func simulateDenial() {
        guard let user = authService?.currentUser else { return }
        
        // Update user's consent status
        user.parentConsentStatus = ParentConsentStatus.denied.rawValue
        
        // Save changes
        do {
            try modelContext.save()
            // Trigger the UI update
            stopPolling()
            showingDeniedView = true
        } catch {
            print("Error saving denial: \(error)")
        }
    }
    #endif
}

// Success view when parent approves
struct ConsentApprovedView: View {
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            Color.green.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.white)
                
                Text("You're All Set!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Your parent has approved your access.\nEnjoy using Haumana!")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 50)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(25)
                }
                .padding(.top, 20)
            }
        }
    }
}

// Denied view when parent denies
struct ConsentDeniedView: View {
    let onSignOut: () -> Void
    
    var body: some View {
        ZStack {
            Color.lehuaRed
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.white)
                
                Text("Access Not Approved")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Your parent or guardian has not approved access to this app. Please talk to them if you have questions.")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Button(action: onSignOut) {
                    Text("Sign Out")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.red)
                        .padding(.horizontal, 50)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(25)
                }
                .padding(.top, 20)
            }
        }
    }
}
