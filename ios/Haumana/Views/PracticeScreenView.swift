//
//  PracticeScreenView.swift
//  haumana
//
//  Created on 6/3/2025.
//

import SwiftUI

struct PracticeScreenView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: PracticeViewModel
    
    var body: some View {
        NavigationStack {
            if let piece = viewModel.currentPiece {
                VStack {
                    Text(piece.title)
                        .font(.largeTitle)
                        .padding()
                    
                    Text("Practice screen coming in Phase 3")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Done") {
                        Task {
                            await viewModel.endPractice()
                            dismiss()
                        }
                    }
                    .padding()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            Task {
                                await viewModel.endPractice()
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
    }
}