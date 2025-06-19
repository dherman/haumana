import Foundation
import SwiftData
import UIKit

@MainActor
protocol AuthenticationServiceProtocol: AnyObject, Observable {
    var currentUser: User? { get }
    var isSignedIn: Bool { get }
    var modelContext: ModelContext { get }
    
    func checkAuthenticationStatus()
    func signIn(presenting viewController: UIViewController) async throws
    func signOut() async
    func restorePreviousSignIn() async
}