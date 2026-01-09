import Foundation
import GoogleSignIn
import SwiftData
import SwiftUI

@Observable
@MainActor
class HybridAuthenticationService: AuthenticationServiceProtocol {
    private(set) var currentUser: User? {
        didSet {
            if oldValue?.id != currentUser?.id {
                NotificationCenter.default.post(name: NSNotification.Name("AuthStateChanged"), object: nil)
            }
        }
    }
    
    private(set) var isSignedIn: Bool = false {
        didSet {
            if oldValue != isSignedIn {
                NotificationCenter.default.post(name: NSNotification.Name("AuthStateChanged"), object: nil)
            }
        }
    }
    
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Skip Google Sign-In configuration if we're in a test environment
        let isTestEnvironment = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        if !isTestEnvironment {
            configureGoogleSignIn()
            checkAuthenticationStatus()
        }
    }
    
    private func configureGoogleSignIn() {
        // Configure Google Sign-In
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let clientId = dict["GIDClientID"] as? String else {
            print("Error: Could not find GIDClientID in Info.plist")
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    }
    
    func checkAuthenticationStatus() {
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
            // Check if user has existing Google Sign-In session
            GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
                if let user = user {
                    print("Restored previous Google Sign-In for user: \(user.profile?.email ?? "unknown")")
                    Task {
                        await self?.handleGoogleSignInSuccess(user: user)
                    }
                } else {
                    print("No previous Google Sign-In session found")
                    DispatchQueue.main.async {
                        self?.currentUser = nil
                        self?.isSignedIn = false
                    }
                }
            }
        } else {
            // UI test mode but not authenticated
            currentUser = nil
            isSignedIn = false
        }
    }
    
    func signIn(presenting viewController: UIViewController) async throws {
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
            // Use Google Sign-In SDK
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                DispatchQueue.main.async {
                    GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { result, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }
                        
                        guard let user = result?.user else {
                            continuation.resume(throwing: NSError(
                                domain: "HybridAuth",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "No user returned from Google Sign-In"]
                            ))
                            return
                        }
                        
                        Task { [weak self] in
                            if let self = self {
                                await self.handleGoogleSignInSuccess(user: user)
                            }
                            continuation.resume()
                        }
                    }
                }
            }
        }
    }
    
    func signOut() async {
        print("HybridAuthenticationService: Starting sign out")
        
        // Clear local state immediately for UI responsiveness
        currentUser = nil
        isSignedIn = false
        
        if !ProcessInfo.processInfo.arguments.contains("-UITestMode") {
            // Sign out from Google only - no Amplify involvement
            GIDSignIn.sharedInstance.signOut()
            
            // No need to call Amplify.Auth.signOut() in hybrid approach
            // This avoids the Cognito Hosted UI redirect
            
            print("HybridAuthenticationService: Sign out complete - Google session cleared")
        }
    }
    
    func restorePreviousSignIn() async {
        print("HybridAuthenticationService: restorePreviousSignIn called")
        // In test mode, check for mock authenticated state
        if ProcessInfo.processInfo.arguments.contains("-UITestMode") {
            checkAuthenticationStatus()
            return
        }
        
        // For hybrid auth, this is handled in checkAuthenticationStatus
        // which calls GIDSignIn.sharedInstance.restorePreviousSignIn
    }
    
    private func handleGoogleSignInSuccess(user: GIDGoogleUser) async {
        do {
            // Get the Google ID token
            guard let idToken = user.idToken?.tokenString else {
                throw NSError(domain: "HybridAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No ID token from Google"])
            }
            
            // Exchange Google token for AWS credentials
            try await exchangeTokenForCredentials(provider: "accounts.google.com", token: idToken)
            
            // Create or update local user
            await loadOrCreateUser(from: user)
            
        } catch {
            print("Error handling Google sign-in: \(error)")
            currentUser = nil
            isSignedIn = false
        }
    }
    
    private func exchangeTokenForCredentials(provider: String, token: String) async throws {
        // Call our Lambda function to exchange Google token for Cognito credentials
        let apiEndpoint = "https://vageu42qbg.execute-api.us-west-2.amazonaws.com/prod/auth/sync"
        
        guard let url = URL(string: apiEndpoint) else {
            throw NSError(domain: "HybridAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid API endpoint"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "googleIdToken": token
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "HybridAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "HybridAuth", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // Parse the response
        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let success = json["success"] as? Bool,
           success {
            print("Successfully synchronized user with Cognito User Pool")
            if let user = json["user"] as? [String: Any] {
                print("User synchronized: \(user["email"] ?? "unknown")")
            }
        }
    }
    
    private func loadOrCreateUser(from googleUser: GIDGoogleUser) async {
        let profile = googleUser.profile
        let userId = googleUser.userID ?? UUID().uuidString
        let email = profile?.email ?? ""
        let displayName = profile?.name
        let photoUrl = profile?.imageURL(withDimension: 200)?.absoluteString

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
    
    // Get current Google ID token for API authentication
    func getCurrentIdToken() async throws -> String? {
        // If in test mode, return a mock token
        if ProcessInfo.processInfo.arguments.contains("-UITestMode") {
            return "mock-google-id-token"
        }
        
        // Get current user from Google Sign-In
        guard let currentGoogleUser = GIDSignIn.sharedInstance.currentUser else {
            print("No current Google user found")
            return nil
        }
        
        // Check if token needs refresh
        if currentGoogleUser.idToken?.expirationDate ?? Date.distantPast < Date() {
            print("Google ID token expired, refreshing...")
            do {
                let freshUser = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GIDGoogleUser, Error>) in
                    currentGoogleUser.refreshTokensIfNeeded { user, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if let user = user {
                            continuation.resume(returning: user)
                        } else {
                            continuation.resume(throwing: NSError(domain: "HybridAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to refresh tokens"]))
                        }
                    }
                }
                return freshUser.idToken?.tokenString
            } catch {
                print("Error refreshing Google tokens: \(error)")
                throw error
            }
        }
        
        return currentGoogleUser.idToken?.tokenString
    }
}