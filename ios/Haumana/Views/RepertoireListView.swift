import SwiftUI
import SwiftData

struct RepertoireListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.authService) private var authService
    @Query private var pieces: [Piece]
    @State private var showingAddView = false
    @State private var searchText = ""
    @State private var selectedFilter: FilterOption = .all
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case oli = "Oli"
        case mele = "Mele"
        case favorites = "Favorites"
        
        var systemImage: String {
            switch self {
            case .all: return "music.note.list"
            case .oli: return "waveform"
            case .mele: return "music.note"
            case .favorites: return "star.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if filteredPieces.isEmpty && searchText.isEmpty {
                    emptyStateView
                } else {
                    listView
                }
            }
            .navigationTitle("Repertoire")
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
        VStack(spacing: 0) {
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FilterOption.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.rawValue,
                            systemImage: filter.systemImage,
                            isSelected: selectedFilter == filter,
                            count: getFilterCount(for: filter)
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFilter = filter
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            
            Divider()
            
            List {
                if filteredPieces.isEmpty && !searchText.isEmpty {
                    // Search returned no results
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No results for \"\(searchText)\"")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredPieces) { piece in
                        NavigationLink(destination: PieceDetailView(piece: piece)) {
                            PieceRowView(piece: piece)
                        }
                    }
                    .onDelete(perform: deletePieces)
                }
            }
        }
    }
    
    private var filteredPieces: [Piece] {
        // Filter by authenticated user
        guard let userId = authService?.currentUser?.id else {
            return []
        }
        
        var filtered = pieces.filter { piece in
            piece.userId == userId
        }
        
        // Apply filter option
        switch selectedFilter {
        case .all:
            break
        case .oli:
            filtered = filtered.filter { $0.categoryEnum == .oli }
        case .mele:
            filtered = filtered.filter { $0.categoryEnum == .mele }
        case .favorites:
            filtered = filtered.filter { $0.isFavorite }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { piece in
                piece.title.localizedCaseInsensitiveContains(searchText) ||
                piece.lyrics.localizedCaseInsensitiveContains(searchText) ||
                (piece.author?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return filtered
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
    
    private func getFilterCount(for filter: FilterOption) -> Int {
        guard let userId = authService?.currentUser?.id else {
            return 0
        }
        
        let userPieces = pieces.filter { $0.userId == userId }
        
        switch filter {
        case .all:
            return userPieces.count
        case .oli:
            return userPieces.filter { $0.categoryEnum == .oli }.count
        case .mele:
            return userPieces.filter { $0.categoryEnum == .mele }.count
        case .favorites:
            return userPieces.filter { $0.isFavorite }.count
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
                
                HStack(spacing: 8) {
                    // Practice availability indicator
                    if !piece.includeInPractice {
                        Image(systemName: "minus.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Favorite star
                    if piece.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                    
                    PieceCategoryBadge(category: piece.categoryEnum)
                }
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
                    .fill(category == .oli ? AppConstants.oliColor.opacity(0.2) : AppConstants.meleColor.opacity(0.2))
            )
            .foregroundColor(category == .oli ? AppConstants.oliColor : AppConstants.meleColor)
    }
}

struct FilterChip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                if count > 0 {
                    Text("(\(count))")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.accentColor : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
    }
}