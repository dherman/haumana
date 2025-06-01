//
//  RepertoireListView.swift
//  haumana
//
//  Created on 6/1/2025.
//

import SwiftUI
import SwiftData

struct RepertoireListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: RepertoireListViewModel?
    
    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    if viewModel.pieces.isEmpty && !viewModel.isSearching {
                        emptyStateView
                    } else {
                        listView
                    }
                } else {
                    ProgressView()
                        .onAppear {
                            self.viewModel = RepertoireListViewModel(repository: PieceRepository(modelContext: modelContext))
                            self.viewModel?.loadPieces()
                        }
                }
            }
            .navigationTitle("Haumana")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    addButton
                }
            }
            .searchable(text: Binding(
                get: { viewModel?.searchText ?? "" },
                set: { viewModel?.searchText = $0 }
            ), isPresented: Binding(
                get: { viewModel?.isSearching ?? false },
                set: { viewModel?.isSearching = $0 }
            ))
            .onSubmit(of: .search) {
                viewModel?.searchPieces()
            }
            .onChange(of: viewModel?.isSearching ?? false) { _, isSearching in
                if !isSearching && viewModel?.searchText.isEmpty == true {
                    viewModel?.clearSearch()
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image("lehua")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .foregroundColor(.secondary)
            
            Text("Start building your repertoire")
                .font(.title2)
                .multilineTextAlignment(.center)
            
            Button(action: {
                // Navigate to add piece
            }) {
                Text("Add your first oli or mele")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    private var listView: some View {
        List {
            ForEach(viewModel?.pieces ?? []) { piece in
                PieceRowView(piece: piece)
            }
            .onDelete(perform: deletePieces)
        }
        .refreshable {
            viewModel?.loadPieces()
        }
    }
    
    private var addButton: some View {
        Button(action: {
            // Navigate to add piece
        }) {
            Image(systemName: "plus")
        }
    }
    
    private func deletePieces(at offsets: IndexSet) {
        guard let viewModel = viewModel else { return }
        for index in offsets {
            if index < viewModel.pieces.count {
                viewModel.deletePiece(viewModel.pieces[index])
            }
        }
    }
}

struct PieceRowView: View {
    let piece: Piece
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(piece.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Spacer()
                
                CategoryBadge(category: piece.categoryEnum)
            }
            
            Text(piece.lyricsPreview)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
    }
}

struct CategoryBadge: View {
    let category: PieceCategory
    
    var body: some View {
        Text(category.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(category == .oli ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
            )
            .foregroundColor(category == .oli ? .blue : .green)
    }
}