//
//  LineAlignedLyricsView.swift
//  haumana
//
//  Created on 6/3/2025.
//

import SwiftUI

struct LineAlignedLyricsView: View {
    let originalText: String
    let translationText: String
    
    private var linesPairs: [(original: String, translation: String)] {
        let originalLines = originalText.components(separatedBy: .newlines)
        let translationLines = translationText.components(separatedBy: .newlines)
        
        var pairs: [(String, String)] = []
        let maxCount = max(originalLines.count, translationLines.count)
        
        for i in 0..<maxCount {
            let original = i < originalLines.count ? originalLines[i] : ""
            let translation = i < translationLines.count ? translationLines[i] : ""
            pairs.append((original, translation))
        }
        
        return pairs
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left side - Original text
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(Array(linesPairs.enumerated()), id: \.offset) { index, pair in
                            Text(pair.original)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                .frame(width: geometry.size.width / 2)
                
                // Right side - Translation with grey background
                ZStack {
                    Color(.systemGray6)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(Array(linesPairs.enumerated()), id: \.offset) { index, pair in
                                Text(pair.translation)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
                .frame(width: geometry.size.width / 2)
            }
        }
    }
}