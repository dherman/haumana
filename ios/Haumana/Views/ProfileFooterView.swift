import SwiftUI

struct ProfileFooterView: View {
    let appVersion: String
    let onExportData: () -> Void
    let isExportingData: Bool
    
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
            
            // Privacy Section
            Section("Privacy") {
                Button(action: onExportData) {
                    HStack {
                        Label("Export My Data", systemImage: "square.and.arrow.up")
                        Spacer()
                        if isExportingData {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .disabled(isExportingData)
                
                NavigationLink(destination: Text("Data Deletion Coming Soon")) {
                    Label("Request Data Deletion", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }
            
            // Legal Section
            Section("Legal") {
                Link(destination: URL(string: "https://haumana.app/legal/privacy-policy")!) {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Link(destination: URL(string: "https://haumana.app/legal/terms-of-service")!) {
                    HStack {
                        Text("Terms of Service")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                NavigationLink(destination: AcknowledgmentsView()) {
                    Text("Acknowledgments")
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