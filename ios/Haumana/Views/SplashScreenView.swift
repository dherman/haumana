//
//  SplashScreenView.swift
//  haumana
//
//  Created by David Herman on 5/29/25.
//

import SwiftUI
import SwiftData

struct SplashScreenView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isActive = false
    @State private var opacity = 0.0
    @State private var scale = 0.8
    @State private var blossomOpacity = 0.0
    @State private var blossomScale = 1.2
    @State private var authService: AuthenticationServiceProtocol?
    @State private var syncService: SyncService?
    
    var body: some View {
        ZStack {
            // White background
            Color.white
                .ignoresSafeArea(.all)
            
            // Red background image
            Image("red")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: UIScreen.main.bounds.width * 1.2, height: UIScreen.main.bounds.height * 1.2)
                .opacity(blossomOpacity)
                .scaleEffect(blossomScale)
                .blur(radius: 1.0) // Soft focus effect for background
                .clipped()
            
            // Semi-transparent overlay for text readability
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.3),
                    Color.clear,
                    Color.white.opacity(0.4)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                Spacer()
                
                // Main app title with Borel font
                Text("Haumana")
                    .font(.custom("Borel-Regular", size: 60))
                    .foregroundColor(.white) // White text on red background
                    .opacity(opacity)
                    .scaleEffect(scale)
                    .shadow(color: .black, radius: 6, x: 0, y: 2) // Dark shadow for depth
                    .tracking(0.5) // Reduced kerning for better spacing
                                
                Spacer()
                
                // Bottom spacing for safe area
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 120)
            }
        }
        .onAppear {
            // Initialize authentication service
            // TODO: Add a feature flag to switch between services
            authService = HybridAuthenticationService(modelContext: modelContext)
            
            // Initialize sync service
            if let authService = authService {
                syncService = SyncService(modelContext: modelContext, authService: authService)
            }
            
            // Animate blossom first
            withAnimation(.easeInOut(duration: 2.0)) {
                blossomOpacity = 1.0  // Full opacity for vibrant image
                blossomScale = 1.0
            }
            
            // Then animate text
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 1.8)) {
                    opacity = 1.0
                    scale = 1.0
                }
            }
            
            // Restore previous sign-in if available
            Task {
                await authService?.restorePreviousSignIn()
            }
            
            // Auto-transition after splash screen duration
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.splashScreenDuration) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    isActive = true
                }
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            if let authService = authService {
                OnboardingCoordinator()
                    .environment(\.authService, authService)
                    .environment(\.syncService, syncService)
            }
        }
    }
}

// Enhanced color extensions
extension Color {
    /// Lehua blossom red - the iconic scarlet red color (#DC143C)
    static let lehuaRed = Color(red: 0.863, green: 0.078, blue: 0.235)
    
    /// Cream color for text (#FFFDD0)
    static let cream = Color(red: 1.0, green: 0.992, blue: 0.816)
    
    /// Deep green for potential accent elements
    static let deepGreen = Color(red: 0.0, green: 0.392, blue: 0.0)
    
    /// Utility functions for color manipulation
    func lighter(by percentage: CGFloat = 0.2) -> Color {
        return self.opacity(1.0 - percentage)
    }
    
    func darker(by percentage: CGFloat = 0.2) -> Color {
        let components = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
        let red = max(0, components[0] - percentage)
        let green = max(0, components[1] - percentage)
        let blue = max(0, components[2] - percentage)
        return Color(red: red, green: green, blue: blue)
    }
}

#Preview {
    SplashScreenView()
} 
