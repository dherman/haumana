//
//  SignInView.swift
//  haumana
//
//  Created on 6/12/2025.
//

import SwiftUI

struct SignInView: View {
    @Environment(\.authService) private var authService
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var titleScale: CGFloat = 0.8
    @State private var titleOpacity: Double = 0.0
    @State private var buttonScale: CGFloat = 0.9
    @State private var buttonOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Full-screen red background (lehua color)
            Color.lehuaRed
                .ignoresSafeArea()
            
            // Centered content
            VStack(spacing: 50) {
                // App title with animation
                Text("Haumana")
                    .font(.custom("Borel-Regular", size: 60))
                    .foregroundColor(.white)
                    .scaleEffect(titleScale)
                    .opacity(titleOpacity)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                
                // Google Sign-In button
                Button(action: signIn) {
                    HStack(spacing: 12) {
                        Image(systemName: "g.circle.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                        
                        Text("Sign in with Google")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.black.opacity(0.54))
                    }
                    .frame(width: 280, height: 50)
                    .background(Color.white)
                    .cornerRadius(25)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                .disabled(isLoading)
                .scaleEffect(buttonScale)
                .opacity(buttonOpacity)
                
                // Loading state text
                if isLoading {
                    Text("Signing in...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 20)
                        .transition(.opacity)
                }
            }
            
            // Loading overlay
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .alert(
            "Sign-In Error",
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
        .onAppear {
            // Animate in the title
            withAnimation(.easeOut(duration: 0.8)) {
                titleScale = 1.0
                titleOpacity = 1.0
            }
            
            // Animate in the button after a delay
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                buttonScale = 1.0
                buttonOpacity = 1.0
            }
        }
    }
    
    private func signIn() {
        guard let authService = authService else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Get the root view controller for presentation
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = windowScene.windows.first,
                      let rootViewController = window.rootViewController else {
                    throw NSError(domain: "SignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to find window for sign in"])
                }
                
                try await authService.signIn(presenting: rootViewController)
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isLoading = false
        }
    }
}

#Preview {
    SignInView()
}