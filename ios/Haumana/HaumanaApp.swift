//
//  haumanaApp.swift
//  haumana
//
//  Created by David Herman on 5/29/25.
//

import SwiftUI
import SwiftData
import CoreText
import GoogleSignIn

@main
struct haumanaApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Piece.self,
            PracticeSession.self,
            User.self
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
        
        // Configure Google Sign-In
        configureGoogleSignIn()
    }

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
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
    
    /// Configure Google Sign-In
    private func configureGoogleSignIn() {
        // Check if we're in UI test mode
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-UITestMode")
        
        if isUITesting {
            // Skip Google Sign-In configuration for UI tests
            print("Running in UI test mode - skipping Google Sign-In configuration")
            return
        }
        
        // Load Google Sign-In configuration from plist
        guard let path = Bundle.main.path(forResource: "GoogleSignIn", ofType: "plist") else {
            // In test environments, the plist might not be available
            if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
                print("Running in test environment - Google Sign-In plist not found")
                return
            }
            
            fatalError("""
                GoogleSignIn.plist not found in app bundle.
                
                To fix this:
                1. In Xcode, right-click on the Haumana folder
                2. Select 'Add Files to haumana'  
                3. Navigate to ios/Haumana/GoogleSignIn.plist
                4. Make sure 'Copy items if needed' is checked
                5. Make sure the 'haumana' target is selected
                6. Click 'Add'
                """)
        }
        
        guard let dict = NSDictionary(contentsOfFile: path),
              let clientID = dict["CLIENT_ID"] as? String else {
            fatalError("Could not parse Google Sign-In credentials from GoogleSignIn.plist")
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }
}
