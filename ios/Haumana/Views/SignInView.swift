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
    
    var body: some View {
        ZStack {
            // Full-screen red background (lehua color)
            Color(red: 0.8, green: 0.2, blue: 0.2)
                .ignoresSafeArea()
            
            // Centered sign-in button
            VStack(spacing: 40) {
                // App title
                Text("Haumana")
                    .font(.custom("Adelia", size: 60))
                    .foregroundColor(.white)
                
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
                        }
                        .frame(width: 280, height: 50)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    }
                    .disabled(authViewModel.isLoading)
                    
                    // Loading indicator
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                            .padding(.top, 20)
                    }
                }
            }
            
            // Error alert
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
        }
        .task {
            if authViewModel == nil, let authService = authService {
                authViewModel = AuthenticationViewModel(authService: authService)
            }
        }
    }
}

#Preview {
    SignInView()
}