import SwiftUI
import SwiftData

struct PieceDetailView: View {
    let piece: Piece
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    @State private var showingPracticeScreen = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title and Category
                HStack {
                    Text(piece.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        CategoryBadge(category: piece.categoryEnum)
                        
                        if piece.isFavorite {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Text("Favorite")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Practice Status
                if piece.includeInPractice {
                    Button(action: {
                        showingPracticeScreen = true
                    }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("Practice Now")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                    }
                } else {
                    HStack {
                        Image(systemName: "minus.circle")
                            .foregroundColor(.secondary)
                        Text("Not included in practice")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
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
                
                // English Translation
                if let englishTranslation = piece.englishTranslation, !englishTranslation.isEmpty {
                    Divider()
                    
                    Text("English Translation")
                        .font(.headline)
                        .padding(.top)
                    
                    Text(englishTranslation)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
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
        .fullScreenCover(isPresented: $showingPracticeScreen) {
            PracticeScreenForPieceView(piece: piece, modelContext: modelContext)
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

// Wrapper view for practice screen with specific piece
struct PracticeScreenForPieceView: View {
    let piece: Piece
    let modelContext: ModelContext
    @State private var viewModel: PracticeViewModel
    
    init(piece: Piece, modelContext: ModelContext) {
        self.piece = piece
        self.modelContext = modelContext
        self._viewModel = State(wrappedValue: PracticeViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        PracticeScreenView(viewModel: viewModel)
            .onAppear {
                Task {
                    await viewModel.startSessionForSpecificPiece(piece)
                }
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