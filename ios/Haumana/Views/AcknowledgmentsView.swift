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
            Section("Honoring the Culture") {
                Text("""
                This app is only a tool to help students with their practice routines. It cannot replace \
                traditional teaching methods or cultural protocols. Students \
                should always seek guidance from their kumu and knowledgeable cultural practitioners.
                """)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.vertical, 4)
            }
            
            // Photo Credits Section
            Section("Photo Credits") {
                // Red flower image
                PhotoCreditRow(
                    title: "Red ʻŌhiʻa Lehua Blossom",
                    photographer: "David Herman",
                    license: "CC BY 4.0",
                    sourceURL: "https://github.com/dherman/haumana/blob/main/assets/red.jpg",
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
            
            // Font Credits Section
            Section("Font Credits") {
                TypefaceRow(
                    name: "Borel",
                    designer: "Rosalie Wagner",
                    license: "SIL Open Font License 1.1",
                    sourceURL: "https://fonts.google.com/specimen/Borel"
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

struct TypefaceRow: View {
    let name: String
    let designer: String
    let license: String
    let sourceURL: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.system(size: 15, weight: .medium))
            
            Text("Designed by \(designer)")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            
            HStack {
                Text(license)
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
                
                Spacer()
                
                Link(destination: URL(string: sourceURL)!) {
                    HStack(spacing: 4) {
                        Text("View on Google Fonts")
                        Image(systemName: "arrow.up.right.square")
                    }
                    .font(.system(size: 12))
                }
            }
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
