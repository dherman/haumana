//
//  SignInView.swift
//  haumana
//
//  Created on 6/12/2025.
//

import SwiftUI
import GoogleSignIn

struct SignInView: View {
    @Environment(\.authService) private var authService
    @State private var authViewModel: AuthenticationViewModel?
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
                    .font(.custom("Adelia", size: 60))
                    .foregroundColor(.white)
                    .scaleEffect(titleScale)
                    .opacity(titleOpacity)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                
                // Google Sign-In button
                if let authViewModel = authViewModel {
                    Button(action: {
                        Task {
                            await authViewModel.signIn()
                        }
                    }) {
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
                    .disabled(authViewModel.isLoading)
                    .scaleEffect(buttonScale)
                    .opacity(buttonOpacity)
                    
                    // Loading state text
                    if authViewModel.isLoading {
                        Text("Signing in...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, 20)
                            .transition(.opacity)
                    }
                }
            }
            
            // Loading overlay
            if authViewModel?.isLoading == true {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel?.isLoading)
        .alert(
            "Sign-In Error",
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
        .task {
            if authViewModel == nil, let authService = authService {
                authViewModel = AuthenticationViewModel(authService: authService)
            }
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
}

#Preview {
    SignInView()
}