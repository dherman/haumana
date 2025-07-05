//
//  ParentEmailCollectionView.swift
//  haumana
//
//  Created on 7/5/2025.
//

import SwiftUI

struct ParentEmailCollectionView: View {
    @State private var parentEmail = ""
    @State private var isSubmitting = false
    
    let onSubmit: (String) -> Void
    
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
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Content container
            VStack(spacing: 30) {
                // Icon or illustration with shadow for better visibility
                Image(systemName: "person.2.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .shadow(radius: 10)
                    .padding(.top, 50)
                
                // Title
                Text("Parent Permission Required")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(radius: 5)
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
                        tintColor: UIColor(Color.blue),
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
                Button(action: { onSubmit(parentEmail) }) {
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
                                   .white.opacity(0.6) : Color.blue)
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}