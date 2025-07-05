//
//  ConsentStatusViews.swift
//  haumana
//
//  Created on 7/5/2025.
//

import SwiftUI

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