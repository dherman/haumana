import Foundation
import SwiftUI
import GoogleSignIn

@MainActor
@Observable
final class AuthenticationViewModel {
    private let authService: AuthenticationService
    
    // Published state
    var user: User? { authService.currentUser }
    var isSignedIn: Bool { authService.isSignedIn }
    var isLoading = false
    var showingSignOutConfirmation = false
    var errorMessage: String?
    var shouldNavigateToRepertoire = false
    
    init(authService: AuthenticationService) {
        self.authService = authService
    }
    
    func signIn() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Get the root view controller
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                throw AuthenticationError.noViewController
            }
            
            try await authService.signIn(presenting: rootViewController)
            
            // After successful sign-in, check if user has any pieces
            if let userId = authService.currentUser?.id {
                let pieceRepository = PieceRepository(modelContext: authService.modelContext)
                let userPieces = try pieceRepository.fetchAll(userId: userId)
                
                // Set flag for navigation if repertoire is empty
                shouldNavigateToRepertoire = userPieces.isEmpty
            }
        } catch {
            errorMessage = "Sign in failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func signOut() {
        showingSignOutConfirmation = true
    }
    
    func confirmSignOut() {
        authService.signOut()
        showingSignOutConfirmation = false
    }
}

enum AuthenticationError: LocalizedError {
    case noViewController
    
    var errorDescription: String? {
        switch self {
        case .noViewController:
            return "Unable to find view controller for sign in"
        }
    }
}