//
//  AgeVerificationView.swift
//  haumana
//
//  Created on 7/2/2025.
//

import SwiftUI

struct AgeVerificationView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var birthdate: Date?
    let onComplete: (Date) -> Void
    
    @State private var selectedDate = Calendar.current.date(byAdding: .year, value: -13, to: Date()) ?? Date()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var maximumDate: Date {
        Date()
    }
    
    private var minimumDate: Date {
        Calendar.current.date(byAdding: .year, value: -100, to: Date()) ?? Date()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                KohalaBackgroundView()
                
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .symbolRenderingMode(.hierarchical)
                            .shadow(radius: 10)
                        
                        Text("Verify Your Age")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                        
                        Text("This is to make sure you have a safe and helpful experience whatever your age.")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 40)
                    
                    // Date Picker
                    VStack(spacing: 12) {
                        Text("Enter your birthdate")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        DatePicker(
                            "",
                            selection: $selectedDate,
                            in: minimumDate...maximumDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .background(Color.white.opacity(0.95))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    // Continue Button
                    Button(action: verifyAge) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(28)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Invalid Date", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func verifyAge() {
        let calendar = Calendar.current
        let now = Date()
        
        // Check if date is in the future
        if selectedDate > now {
            alertMessage = "Please enter a valid birthdate."
            showingAlert = true
            return
        }
        
        // Check if age is reasonable (not more than 100 years old)
        if let hundredYearsAgo = calendar.date(byAdding: .year, value: -100, to: now),
           selectedDate < hundredYearsAgo {
            alertMessage = "Please enter a valid birthdate."
            showingAlert = true
            return
        }
        
        // All validation passed
        birthdate = selectedDate
        onComplete(selectedDate)
    }
}

#Preview {
    AgeVerificationView(birthdate: .constant(nil)) { date in
        print("Selected date: \(date)")
    }
}
