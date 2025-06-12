import SwiftUI

struct AuthenticatedProfileView: View {
    let user: User
    let profileStats: ProfileStats
    let recentSessions: [SessionWithPiece]
    let onSignOut: () -> Void
    
    struct ProfileStats {
        let currentStreak: Int
        let totalSessions: Int
        let mostPracticedPiece: Piece?
        let mostPracticedCount: Int
    }
    
    var body: some View {
        Group {
            // User Section
            Section {
                HStack(spacing: 16) {
                    // Profile Photo
                    if let photoUrl = user.photoUrl,
                       let url = URL(string: photoUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                    }
                    
                    // User Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.displayName ?? "Haumana User")
                            .font(.headline)
                        Text(user.email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                
                Button(action: onSignOut) {
                    Text("Sign Out")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Practice Statistics Section
            Section("Practice Statistics") {
                StatRow(
                    icon: "flame",
                    title: "Current Streak",
                    value: "\(profileStats.currentStreak) days"
                )
                
                StatRow(
                    icon: "music.note",
                    title: "Total Sessions",
                    value: "\(profileStats.totalSessions)"
                )
                
                if let mostPracticed = profileStats.mostPracticedPiece {
                    HStack {
                        Label("Most Practiced", systemImage: "star")
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(mostPracticed.title)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            Text("\(profileStats.mostPracticedCount) times")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Recent Practice History
            if !recentSessions.isEmpty {
                Section("Recent Practice") {
                    ForEach(recentSessions.prefix(5)) { sessionWithPiece in
                        NavigationLink(destination: PieceDetailView(piece: sessionWithPiece.piece)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(sessionWithPiece.piece.title)
                                        .font(.body)
                                    Text(formatSessionDate(sessionWithPiece.session.startTime))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(formatSessionDuration(sessionWithPiece.session))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            
            // Sync Status Section (Placeholder for future)
            Section("Data Sync") {
                HStack {
                    Label("Sync Status", systemImage: "icloud")
                    Spacer()
                    Text("Coming Soon")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func formatSessionDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func formatSessionDuration(_ session: PracticeSession) -> String {
        guard let endTime = session.endTime else {
            return "In progress"
        }
        
        let duration = endTime.timeIntervalSince(session.startTime)
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}