import SwiftUI
import SwiftData

struct PieceDetailView: View {
    let piece: Piece
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title and Category
                HStack {
                    Text(piece.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    CategoryBadge(category: piece.categoryEnum)
                }
                
                // Author
                if let author = piece.author, !author.isEmpty {
                    Label(author, systemImage: "person")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Language
                HStack {
                    Label(languageDisplay, systemImage: "globe")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Lyrics
                Text(piece.lyrics)
                    .font(.body)
                    .lineSpacing(4)
                
                // Notes
                if let notes = piece.notes, !notes.isEmpty {
                    Divider()
                    
                    Text("Notes")
                        .font(.headline)
                        .padding(.top)
                    
                    Text(notes)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                // Source URL
                if let sourceUrl = piece.sourceUrl, 
                   !sourceUrl.isEmpty,
                   let url = URL(string: sourceUrl) {
                    Divider()
                    
                    Link(destination: url) {
                        Label("View Source", systemImage: "link")
                            .font(.footnote)
                    }
                    .padding(.top)
                }
                
                // Metadata
                Divider()
                    .padding(.top, 20)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Added")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(piece.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Updated")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(piece.updatedAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                    }
                }
                .padding(.bottom)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEditView = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            NavigationStack {
                AddEditPieceView(piece: piece)
            }
        }
        .alert("Delete Piece?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deletePiece()
            }
        } message: {
            Text("This will permanently delete \"\(piece.title)\". This action cannot be undone.")
        }
    }
    
    private var languageDisplay: String {
        switch piece.language {
        case "haw":
            return "ʻŌlelo Hawaiʻi"
        case "eng":
            return "English"
        default:
            return piece.language
        }
    }
    
    private func deletePiece() {
        modelContext.delete(piece)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to delete piece: \(error)")
        }
    }
}

// Reuse the same CategoryBadge from PieceDetailView
struct CategoryBadge: View {
    let category: PieceCategory
    
    var body: some View {
        Text(category.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(categoryColor.opacity(0.2))
            .foregroundColor(categoryColor)
            .clipShape(Capsule())
    }
    
    private var categoryColor: Color {
        switch category {
        case .oli:
            return .blue
        case .mele:
            return .purple
        }
    }
}