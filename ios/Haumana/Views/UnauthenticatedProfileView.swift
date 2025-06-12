import SwiftUI

struct UnauthenticatedProfileView: View {
    let onSignIn: () async -> Void
    let totalLocalPieces: Int
    let totalLocalSessions: Int
    
    @State private var isSigningIn = false
    
    var body: some View {
        Group {
            // App Branding Section
            Section {
                VStack(spacing: 20) {
                    // Lehua flower image
                    Image("lehua")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.accentColor)
                    
                    VStack(spacing: 8) {
                        Text("Haumana")
                            .font(.largeTitle)
                            .fontWeight(.medium)
                        
                        Text("Practice assistant")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .listRowBackground(Color.clear)
            
            // Sign In Section
            Section {
                VStack(spacing: 16) {
                    Text("Sign in to sync your repertoire across devices")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        Task {
                            isSigningIn = true
                            await onSignIn()
                            isSigningIn = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.up.forward.app")
                                .imageScale(.large)
                            Text("Sign in with Google")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSigningIn)
                    .overlay {
                        if isSigningIn {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.8)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Local Data Info Section
            Section("Your Data") {
                HStack {
                    Label("Local Pieces", systemImage: "music.note.list")
                    Spacer()
                    Text("\(totalLocalPieces)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label("Practice Sessions", systemImage: "clock.fill")
                    Spacer()
                    Text("\(totalLocalSessions)")
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("Data Storage", systemImage: "info.circle")
                    Text("Your repertoire and practice history are currently stored locally on this device. Sign in to enable cloud sync and access your data from any device.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
            
            // Benefits Section
            Section("Why Sign In?") {
                BenefitRow(
                    icon: "icloud",
                    title: "Cloud Sync",
                    description: "Access your repertoire from any device"
                )
                
                BenefitRow(
                    icon: "shield.checkered",
                    title: "Secure Backup",
                    description: "Never lose your practice history"
                )
                
                BenefitRow(
                    icon: "person.2",
                    title: "Future Features",
                    description: "Share repertoire and collaborate (coming soon)"
                )
            }
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}