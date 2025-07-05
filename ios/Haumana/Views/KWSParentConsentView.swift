//
//  KWSParentConsentView.swift
//  haumana
//
//  Created on 7/3/2025.
//

import SwiftUI
import SwiftData

struct KWSParentConsentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.authService) private var authService
    @Environment(\.modelContext) private var modelContext
    
    @State private var parentEmail = ""
    @State private var isSubmitting = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingWaitingView = false
    @State private var wasApproved = false
    
    @StateObject private var consentService: ConsentService
    
    init(modelContext: ModelContext) {
        _consentService = StateObject(wrappedValue: ConsentService(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Lehua red background to match sign-in screen
                Color.lehuaRed
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Icon or illustration
                    Image(systemName: "person.2.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .padding(.top, 50)
                    
                    // Title
                    Text("Parent Permission Required")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Explanation
                    VStack(spacing: 20) {
                        Text("Because you're under 13, we need your parent or guardian's permission to use this app.")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Text("We'll send them an email to get their permission.")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Email input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Parent's Email Address")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        CustomTextField(
                            text: $parentEmail,
                            placeholder: "parent@example.com",
                            placeholderColor: .placeholderText,
                            textColor: .black,
                            tintColor: UIColor(Color.lehuaRed),
                            keyboardType: .emailAddress,
                            autocapitalizationType: .none,
                            isEnabled: !isSubmitting
                        )
                        .frame(height: 44)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Submit button
                    Button(action: requestConsent) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isSubmitting ? "Sending..." : "Send Permission Request")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(parentEmail.isEmpty || !isValidEmail(parentEmail) ? 
                                       .white.opacity(0.6) : Color.lehuaRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(parentEmail.isEmpty || !isValidEmail(parentEmail) ? 
                                      Color.white.opacity(0.2) : Color.white)
                        )
                    }
                    .disabled(parentEmail.isEmpty || !isValidEmail(parentEmail) || isSubmitting)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .fullScreenCover(isPresented: $showingWaitingView, onDismiss: {
            // When waiting view dismisses, check if it was due to approval
            if wasApproved {
                dismiss()
            }
        }) {
            WaitingForParentView(modelContext: modelContext) { approved in
                // Store approval state
                wasApproved = approved
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func requestConsent() {
        guard let user = authService?.currentUser else { return }
        
        isSubmitting = true
        
        Task {
            do {
                try await consentService.requestParentConsent(for: user, parentEmail: parentEmail)
                
                // Show waiting view
                await MainActor.run {
                    showingWaitingView = true
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
}
