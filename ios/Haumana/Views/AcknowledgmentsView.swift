//
//  AcknowledgmentsView.swift
//  haumana
//
//  Created on 7/5/2025.
//

import SwiftUI

struct AcknowledgmentsView: View {
    var body: some View {
        List {
            // Cultural Acknowledgment Section
            Section("Aloha Mēheuheu (Honoring the Culture)") {
                Text("""
                This app is intended to support practice routines of haumana, not to replace \
                traditional teaching methods or cultural protocols. We encourage users always \
                to seek guidance from their kumu and to approach their practice with aloha kānaka \
                and aloha ʻāina.
                """)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.vertical, 4)
            }
            
            // Photo Credits Section
            Section("Photo Credits") {
                // Yellow flower image
                PhotoCreditRow(
                    title: "Yellow ʻŌhiʻa Lehua Blossom",
                    photographer: "David Eickhoff",
                    license: "CC BY 2.0",
                    sourceURL: "https://www.flickr.com/photos/50823119@N08/5113316760",
                    usage: "Splash screen background"
                )
                
                // Kohala image
                PhotoCreditRow(
                    title: "Humpback Whale",
                    photographer: "M Cheng",
                    license: "Public Domain",
                    sourceURL: "https://www.flickr.com/photos/145081981@N02/34343706751",
                    usage: "Parental consent flow background"
                )
            }
            
            // Open Source Software Section
            Section("Open Source Software") {
                OpenSourceRow(
                    name: "GoogleSignIn",
                    version: "8.0.0",
                    license: "Apache 2.0",
                    url: "https://github.com/google/GoogleSignIn-iOS"
                )
                
                OpenSourceRow(
                    name: "AppAuth",
                    version: "1.7.6",
                    license: "Apache 2.0",
                    url: "https://github.com/openid/AppAuth-iOS"
                )
                
                OpenSourceRow(
                    name: "GTMSessionFetcher",
                    version: "3.5.0",
                    license: "Apache 2.0",
                    url: "https://github.com/google/gtm-session-fetcher"
                )
                
                OpenSourceRow(
                    name: "GTMAppAuth",
                    version: "4.1.1",
                    license: "Apache 2.0",
                    url: "https://github.com/google/GTMAppAuth"
                )
            }
        }
        .navigationTitle("Acknowledgments")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }
}

struct PhotoCreditRow: View {
    let title: String
    let photographer: String
    let license: String
    let sourceURL: String
    let usage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
            
            Text("Photo by \(photographer)")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            
            HStack {
                Text(license)
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
                
                Spacer()
                
                Link(destination: URL(string: sourceURL)!) {
                    HStack(spacing: 4) {
                        Text("View Original")
                        Image(systemName: "arrow.up.right.square")
                    }
                    .font(.system(size: 12))
                }
            }
            
            Text(usage)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .italic()
        }
    }
}

struct OpenSourceRow: View {
    let name: String
    let version: String
    let license: String
    let url: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.system(size: 15, weight: .medium))
                
                Spacer()
                
                Text("v\(version)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(license)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Link(destination: URL(string: url)!) {
                    HStack(spacing: 4) {
                        Text("GitHub")
                        Image(systemName: "arrow.up.right.square")
                    }
                    .font(.system(size: 12))
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AcknowledgmentsView()
    }
}