import Foundation
import GoogleSignIn
import SwiftData
import UIKit

@Observable
open class AuthenticationService {
    private(set) var currentUser: User?
    private(set) var isSignedIn: Bool = false
    
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Skip Google Sign-In check if we're in a test environment
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
            checkAuthenticationStatus()
        }
    }
    
    open func checkAuthenticationStatus() {
        // Check if we're in UI test mode with mock authentication
        if ProcessInfo.processInfo.arguments.contains("-MockAuthenticated") {
            // Create a mock authenticated user for testing
            let mockUser = User(
                id: "test-user-123",
                email: "test@example.com",
                displayName: "Test User",
                photoUrl: nil
            )
            
            // Try to fetch existing mock user first
            let descriptor = FetchDescriptor<User>(
                predicate: #Predicate { $0.id == "test-user-123" }
            )
            
            do {
                if let existingUser = try modelContext.fetch(descriptor).first {
                    existingUser.lastLoginAt = Date()
                    currentUser = existingUser
                } else {
                    modelContext.insert(mockUser)
                    currentUser = mockUser
                }
                
                try modelContext.save()
                isSignedIn = true
            } catch {
                print("Error setting up mock user: \(error)")
                currentUser = nil
                isSignedIn = false
            }
        } else if !ProcessInfo.processInfo.arguments.contains("-UITestMode") {
            // Normal production behavior
            if let googleUser = GIDSignIn.sharedInstance.currentUser {
                loadOrCreateUser(from: googleUser)
            } else {
                currentUser = nil
                isSignedIn = false
            }
        } else {
            // UI test mode but not authenticated
            currentUser = nil
            isSignedIn = false
        }
    }
    
    open func signIn(presenting viewController: UIViewController) async throws {
        // Check if we're in UI test mode or any test environment
        let isTestEnvironment = ProcessInfo.processInfo.arguments.contains("-UITestMode") ||
                               ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        
        if isTestEnvironment {
            // Simulate a delay like real sign-in
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Create mock user
            let mockUser = User(
                id: "test-user-123",
                email: "test@example.com",
                displayName: "Test User",
                photoUrl: nil
            )
            
            // Check if user already exists
            let descriptor = FetchDescriptor<User>(
                predicate: #Predicate { $0.id == "test-user-123" }
            )
            
            if let existingUser = try modelContext.fetch(descriptor).first {
                existingUser.lastLoginAt = Date()
                currentUser = existingUser
            } else {
                modelContext.insert(mockUser)
                currentUser = mockUser
            }
            
            try modelContext.save()
            isSignedIn = true
        } else {
            // Normal production behavior
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
            let googleUser = result.user
            
            loadOrCreateUser(from: googleUser)
        }
    }
    
    open func signOut() {
        if !ProcessInfo.processInfo.arguments.contains("-UITestMode") {
            // Only sign out from Google in production
            GIDSignIn.sharedInstance.signOut()
        }
        currentUser = nil
        isSignedIn = false
    }
    
    open func restorePreviousSignIn() async {
        // In test mode, check for mock authenticated state
        if ProcessInfo.processInfo.arguments.contains("-UITestMode") {
            checkAuthenticationStatus()
            return
        }
        
        // Normal production behavior
        do {
            try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            if let googleUser = GIDSignIn.sharedInstance.currentUser {
                loadOrCreateUser(from: googleUser)
            }
        } catch {
            // Silent failure is fine - user just stays signed out
            print("No previous sign-in to restore: \(error)")
        }
    }
    
    private func loadOrCreateUser(from googleUser: GIDGoogleUser) {
        let userId = googleUser.userID ?? ""
        let email = googleUser.profile?.email ?? ""
        let displayName = googleUser.profile?.name
        let photoUrl = googleUser.profile?.imageURL(withDimension: 200)?.absoluteString
        
        // Try to fetch existing user
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == userId }
        )
        
        do {
            if let existingUser = try modelContext.fetch(descriptor).first {
                // Update existing user
                existingUser.lastLoginAt = Date()
                existingUser.email = email
                existingUser.displayName = displayName
                existingUser.photoUrl = photoUrl
                currentUser = existingUser
            } else {
                // Create new user
                let newUser = User(
                    id: userId,
                    email: email,
                    displayName: displayName,
                    photoUrl: photoUrl
                )
                modelContext.insert(newUser)
                currentUser = newUser
            }
            
            try modelContext.save()
            isSignedIn = true
        } catch {
            print("Error saving user: \(error)")
            isSignedIn = false
        }
    }
}