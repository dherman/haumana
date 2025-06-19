//
//  haumanaApp.swift
//  haumana
//
//  Created by David Herman on 5/29/25.
//

import SwiftUI
import SwiftData
import CoreText
import Amplify
import AWSCognitoAuthPlugin
import AWSAPIPlugin

@main
struct haumanaApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Piece.self,
            PracticeSession.self,
            User.self,
            SyncQueueItem.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        // Register custom fonts
        registerCustomFonts()
        
        // Skip configuration if running tests
        let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        
        if !isRunningTests {
            configureAmplify()
        }
    }

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
        }
        .modelContainer(sharedModelContainer)
    }
    
    /// Register custom fonts with the app
    private func registerCustomFonts() {
        // Register Adelia font
        registerFont(resource: "adelia", extension: "ttf", name: "Adelia")
    }
    
    /// Helper function to register a single font
    private func registerFont(resource: String, extension: String, name: String) {
        guard let fontURL = Bundle.main.url(forResource: resource, withExtension: `extension`) else {
            print("Could not find \(resource).\(`extension`) font file")
            return
        }
        
        // Use the modern iOS 18+ API for font registration
        if #available(iOS 13.0, *) {
            var error: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
            
            if !success {
                if let error = error?.takeRetainedValue() {
                    print("Error registering \(name) font: \(error)")
                } else {
                    print("Unknown error registering \(name) font")
                }
            } else {
                print("Successfully registered \(name) font")
            }
        } else {
            // Fallback for older iOS versions
            guard let fontDataProvider = CGDataProvider(url: fontURL as CFURL) else {
                print("Could not create data provider for \(name) font")
                return
            }
            
            guard let font = CGFont(fontDataProvider) else {
                print("Could not create \(name) font from data provider")
                return
            }
            
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterGraphicsFont(font, &error) {
                if let error = error?.takeRetainedValue() {
                    print("Error registering \(name) font: \(error)")
                } else {
                    print("Unknown error registering \(name) font")
                }
            } else {
                print("Successfully registered \(name) font (legacy method)")
            }
        }
    }
    
    
    /// Configure AWS Amplify
    private func configureAmplify() {
        // Check if we're in UI test mode
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-UITestMode")
        
        if isUITesting {
            // Skip Amplify configuration for UI tests
            print("Running in UI test mode - skipping AWS Amplify configuration")
            return
        }
        
        // Check if we're in test environment
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            print("Running in test environment - skipping AWS Amplify configuration")
            return
        }
        
        do {
            // Add Auth plugin
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            
            // Add API plugin
            try Amplify.add(plugin: AWSAPIPlugin())
            
            // Configure Amplify
            try Amplify.configure()
            
            print("Amplify configured successfully")
        } catch {
            print("Failed to configure Amplify: \(error)")
        }
    }
}
