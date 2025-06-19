import SwiftUI

private struct AuthenticationServiceKey: EnvironmentKey {
    static let defaultValue: AuthenticationServiceProtocol? = nil
}

extension EnvironmentValues {
    var authService: AuthenticationServiceProtocol? {
        get { self[AuthenticationServiceKey.self] }
        set { self[AuthenticationServiceKey.self] = newValue }
    }
}