//
//  SplashScreenView.swift
//  haumana
//
//  Created by David Herman on 5/29/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var opacity = 0.0
    @State private var scale = 0.8
    @State private var blossomOpacity = 0.0
    @State private var blossomScale = 1.2
    
    var body: some View {
        ZStack {
            // White background
            Color.white
                .ignoresSafeArea(.all)
            
            // Lehua blossom bitmap image
            Image("lehua")
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
                
                // Main app title with serif font hierarchy
                Text("Haumana")
                    .font(serifFont)
                    .fontWeight(.medium)
                    .foregroundColor(.black) // Changed to black for better readability
                    .opacity(opacity)
                    .scaleEffect(scale)
                    .shadow(color: .white.opacity(0.8), radius: 4, x: 0, y: 0) // White shadow for definition
                    .tracking(0.5) // Reduced kerning for better spacing
                
                // Subtle subtitle
                Text("Practice assistant")
                    .font(UIFont(name: "Adelia", size: 24) != nil ? .custom("Adelia", size: 24) : .custom("Georgia", size: 16))
                    .fontWeight(.light)
                    .foregroundColor(.black) // Changed to black with slight transparency
                    .opacity(opacity)
                    .shadow(color: .white.opacity(0.8), radius: 4, x: 0, y: 0) // White shadow for definition
                    .padding(.top, 12)
                    .tracking(0.3) // Reduced kerning for subtitle too
                
                Spacer()
                
                // Bottom spacing for safe area
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 120)
            }
        }
        .onAppear {
            // Animate blossom first
            withAnimation(.easeInOut(duration: 2.0)) {
                blossomOpacity = 0.7  // Higher opacity for bitmap image
                blossomScale = 1.0
            }
            
            // Then animate text
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 1.8)) {
                    opacity = 1.0
                    scale = 1.0
                }
            }
            
            // Auto-transition after splash screen duration
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.splashScreenDuration) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    isActive = true
                }
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            MainTabView()
        }
    }
    
    /// Preferred serif font with fallbacks
    private var serifFont: Font {
        // Try custom Pearl Hirenha font first
        if UIFont(name: "Pearl Hirenha DEMO VERSION", size: 68) != nil {
            return .custom("Pearl Hirenha DEMO VERSION", size: 68)
        } else {
            // Use fallback serif fonts
            if UIFont(name: "Cochin", size: 68) != nil {
                return .custom("Cochin", size: 68)
            } else if UIFont(name: "HoeflerText-Regular", size: 68) != nil {
                return .custom("HoeflerText-Regular", size: 68)
            } else if UIFont(name: "Palatino", size: 68) != nil {
                return .custom("Palatino", size: 68)
            } else {
                return .custom("Georgia", size: 68)
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
