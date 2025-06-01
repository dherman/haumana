import SwiftUI
import SwiftData

struct RepertoireListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var pieces: [Piece]
    @State private var showingAddView = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            Group {
                if pieces.isEmpty {
                    emptyStateView
                } else {
                    listView
                }
            }
            .navigationTitle("Haumana")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddView = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $searchText)
            .sheet(isPresented: $showingAddView) {
                AddEditPieceView(piece: nil)
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
                showingAddView = true
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
            ForEach(filteredPieces) { piece in
                NavigationLink(destination: PieceDetailView(piece: piece)) {
                    PieceRowView(piece: piece)
                }
            }
            .onDelete(perform: deletePieces)
        }
    }
    
    private var filteredPieces: [Piece] {
        if searchText.isEmpty {
            return pieces
        } else {
            return pieces.filter { piece in
                piece.title.localizedCaseInsensitiveContains(searchText) ||
                piece.lyrics.localizedCaseInsensitiveContains(searchText) ||
                (piece.author?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    private func deletePieces(at offsets: IndexSet) {
        for index in offsets {
            let piece = filteredPieces[index]
            modelContext.delete(piece)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete piece: \(error)")
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
                
                PieceCategoryBadge(category: piece.categoryEnum)
            }
            
            Text(piece.lyricsPreview)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
    }
}

struct PieceCategoryBadge: View {
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