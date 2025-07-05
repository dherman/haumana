//
//  KohalaBackgroundView.swift
//  haumana
//
//  Created on 7/5/2025.
//

import SwiftUI

struct KohalaBackgroundView: View {
    var overlayOpacity: Double = 0.4
    
    var body: some View {
        ZStack {
            // Full screen background image
            GeometryReader { geometry in
                Image("kohala")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            .ignoresSafeArea()
            
            // Dark overlay for better text readability
            Color.black.opacity(overlayOpacity)
                .ignoresSafeArea()
        }
    }
}

#Preview {
    KohalaBackgroundView()
}