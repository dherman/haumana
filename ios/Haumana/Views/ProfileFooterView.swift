import SwiftUI

struct ProfileFooterView: View {
    let appVersion: String
    
    var body: some View {
        Group {
            // Help Section
            Section("Help & Support") {
                NavigationLink(destination: HelpView()) {
                    Label("Practice Guide", systemImage: "questionmark.circle")
                }
                
                Link(destination: URL(string: "mailto:support@haumana.app?subject=Haumana%20Feedback")!) {
                    HStack {
                        Label("Send Feedback", systemImage: "envelope")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Legal Section
            Section("Legal") {
                Link(destination: URL(string: "https://haumana.app/privacy")!) {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Link(destination: URL(string: "https://haumana.app/terms")!) {
                    HStack {
                        Text("Terms of Service")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // About Section
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundColor(.secondary)
                }
                
                Link(destination: URL(string: "https://github.com/dherman/haumana")!) {
                    HStack {
                        Text("View on GitHub")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("🌺")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
            }
        }
    }
}