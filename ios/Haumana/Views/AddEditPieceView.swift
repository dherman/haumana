import SwiftUI
import SwiftData

struct AddEditPieceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.authService) private var authService
    
    @State private var title: String = ""
    @State private var category: PieceCategory = .oli
    @State private var lyrics: String = ""
    @State private var language: String = "haw"
    @State private var englishTranslation: String = ""
    @State private var author: String = ""
    @State private var sourceUrl: String = ""
    @State private var notes: String = ""
    @State private var includeInPractice: Bool = true
    @State private var isFavorite: Bool = false
    
    @State private var showingCancelAlert = false
    @State private var showingValidationError = false
    @State private var validationMessage = ""
    
    @FocusState private var focusedField: Field?
    
    let piece: Piece?
    
    enum Field: Hashable {
        case title, lyrics, englishTranslation, author, sourceUrl, notes
    }
    
    init(piece: Piece? = nil) {
        self.piece = piece
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Title Section
                Section {
                    TextField("Title", text: $title)
                        .focused($focusedField, equals: .title)
                } header: {
                    Text("Title *")
                        .font(.caption)
                        .textCase(.uppercase)
                }
                
                // Category Section
                Section {
                    Picker("Category", selection: $category) {
                        ForEach(PieceCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Category")
                        .font(.caption)
                        .textCase(.uppercase)
                }
                
                // Practice Settings Section
                Section {
                    Toggle("Include in Practice", isOn: $includeInPractice)
                } header: {
                    Text("Practice Settings")
                        .font(.caption)
                        .textCase(.uppercase)
                } footer: {
                    Text("When enabled, this piece will be available for random selection during practice sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Lyrics Section
                Section {
                    TextEditor(text: $lyrics)
                        .focused($focusedField, equals: .lyrics)
                        .frame(minHeight: 120)
                } header: {
                    Text("Lyrics *")
                        .font(.caption)
                        .textCase(.uppercase)
                }
                
                // Language Section
                Section {
                    Picker("Language", selection: $language) {
                        Text("ʻŌlelo Hawaiʻi").tag("haw")
                        Text("English").tag("eng")
                    }
                } header: {
                    Text("Language")
                        .font(.caption)
                        .textCase(.uppercase)
                }
                
                // English Translation Section (optional)
                Section {
                    TextEditor(text: $englishTranslation)
                        .focused($focusedField, equals: .englishTranslation)
                        .frame(minHeight: 120)
                } header: {
                    Text("English Translation (optional)")
                        .font(.caption)
                        .textCase(.uppercase)
                } footer: {
                    Text("Provide a translation to display alongside the original during practice")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Additional Info Section
                Section {
                    TextField("Author (optional)", text: $author)
                        .focused($focusedField, equals: .author)
                    
                    TextField("Source URL (optional)", text: $sourceUrl)
                        .focused($focusedField, equals: .sourceUrl)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                    
                    TextEditor(text: $notes)
                        .focused($focusedField, equals: .notes)
                        .frame(minHeight: 80)
                } header: {
                    Text("Additional Information")
                        .font(.caption)
                        .textCase(.uppercase)
                }
            }
            .navigationTitle(piece == nil ? "Add Piece" : "Edit Piece")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if hasChanges {
                            showingCancelAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            isFavorite.toggle()
                        }) {
                            Image(systemName: isFavorite ? "star.fill" : "star")
                                .foregroundColor(isFavorite ? .yellow : .gray)
                        }
                        
                        Button("Save") {
                            save()
                        }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                    }
                }
            }
            .alert("Discard Changes?", isPresented: $showingCancelAlert) {
                Button("Keep Editing", role: .cancel) { }
                Button("Discard", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
            .alert("Validation Error", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
            .onAppear {
                loadPieceData()
            }
        }
    }
    
    private var hasChanges: Bool {
        if let piece = piece {
            return title != piece.title ||
                   category != piece.categoryEnum ||
                   lyrics != piece.lyrics ||
                   language != piece.language ||
                   englishTranslation != (piece.englishTranslation ?? "") ||
                   author != (piece.author ?? "") ||
                   sourceUrl != (piece.sourceUrl ?? "") ||
                   notes != (piece.notes ?? "") ||
                   includeInPractice != piece.includeInPractice ||
                   isFavorite != piece.isFavorite
        } else {
            return !title.isEmpty || !lyrics.isEmpty || !englishTranslation.isEmpty ||
                   !author.isEmpty || !sourceUrl.isEmpty || !notes.isEmpty ||
                   !includeInPractice || isFavorite
        }
    }
    
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lyrics.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func loadPieceData() {
        guard let piece = piece else { return }
        
        title = piece.title
        category = piece.categoryEnum
        lyrics = piece.lyrics
        language = piece.language
        englishTranslation = piece.englishTranslation ?? ""
        author = piece.author ?? ""
        sourceUrl = piece.sourceUrl ?? ""
        notes = piece.notes ?? ""
        includeInPractice = piece.includeInPractice
        isFavorite = piece.isFavorite
    }
    
    private func save() {
        // Validate
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLyrics = lyrics.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTitle.isEmpty else {
            validationMessage = "Title is required"
            showingValidationError = true
            return
        }
        
        guard !trimmedLyrics.isEmpty else {
            validationMessage = "Lyrics are required"
            showingValidationError = true
            return
        }
        
        // Save
        if let existingPiece = piece {
            // Update existing piece
            existingPiece.title = trimmedTitle
            existingPiece.category = category.rawValue
            existingPiece.lyrics = trimmedLyrics
            existingPiece.language = language
            existingPiece.englishTranslation = englishTranslation.isEmpty ? nil : englishTranslation
            existingPiece.author = author.isEmpty ? nil : author
            existingPiece.sourceUrl = sourceUrl.isEmpty ? nil : sourceUrl
            existingPiece.notes = notes.isEmpty ? nil : notes
            existingPiece.includeInPractice = includeInPractice
            existingPiece.isFavorite = isFavorite
            existingPiece.updatedAt = Date()
        } else {
            // Create new piece
            let newPiece = Piece(
                title: trimmedTitle,
                category: category,
                lyrics: trimmedLyrics,
                language: language,
                englishTranslation: englishTranslation.isEmpty ? nil : englishTranslation,
                author: author.isEmpty ? nil : author,
                sourceUrl: sourceUrl.isEmpty ? nil : sourceUrl,
                notes: notes.isEmpty ? nil : notes
            )
            newPiece.includeInPractice = includeInPractice
            newPiece.isFavorite = isFavorite
            newPiece.userId = authService?.currentUser?.id
            modelContext.insert(newPiece)
        }
        
        // Save context
        do {
            try modelContext.save()
            dismiss()
        } catch {
            validationMessage = "Failed to save: \(error.localizedDescription)"
            showingValidationError = true
        }
    }
}