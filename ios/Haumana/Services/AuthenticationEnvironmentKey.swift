import SwiftUI

private struct AuthenticationServiceKey: EnvironmentKey {
    static let defaultValue: AuthenticationService? = nil
}

extension EnvironmentValues {
    var authService: AuthenticationService? {
        get { self[AuthenticationServiceKey.self] }
        set { self[AuthenticationServiceKey.self] = newValue }
    }
}