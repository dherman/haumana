//
//  MainTabView.swift
//  haumana
//
//  Created on 6/3/2025.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            PracticeTabView()
                .tabItem {
                    Label("Practice", systemImage: "music.note.list")
                }
            
            RepertoireListView()
                .tabItem {
                    Label("Repertoire", systemImage: "square.text.square.fill")
                }
            
            ProfileTabView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
        }
    }
}