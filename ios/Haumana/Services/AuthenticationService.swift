import Foundation
import GoogleSignIn
import SwiftData

@Observable
class AuthenticationService {
    private(set) var currentUser: User?
    private(set) var isSignedIn: Bool = false
    
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        checkAuthenticationStatus()
    }
    
    func checkAuthenticationStatus() {
        if let googleUser = GIDSignIn.sharedInstance.currentUser {
            loadOrCreateUser(from: googleUser)
        } else {
            currentUser = nil
            isSignedIn = false
        }
    }
    
    func signIn(presenting viewController: UIViewController) async throws {
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
        let googleUser = result.user
        
        loadOrCreateUser(from: googleUser)
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        currentUser = nil
        isSignedIn = false
    }
    
    func restorePreviousSignIn() async {
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