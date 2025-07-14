//
//  PrivacyService.swift
//  haumana
//
//  Created on 7/12/2025.
//

import Foundation

class PrivacyService {
    private let authService: AuthenticationServiceProtocol
    
    init(authService: AuthenticationServiceProtocol) {
        self.authService = authService
    }
    
    /// Export user data from the backend
    func exportUserData() async throws -> Data {
        guard await authService.isSignedIn else {
            throw PrivacyError.notAuthenticated
        }
        
        guard let currentUser = await authService.currentUser else {
            throw PrivacyError.noUserData
        }
        
        // Get current ID token
        guard let idToken = try await authService.getCurrentIdToken() else {
            throw PrivacyError.noAuthToken
        }
        
        // Construct API URL
        guard let url = URL(string: "\(AppConstants.apiEndpoint)/users/\(currentUser.id)/export") else {
            throw PrivacyError.invalidURL
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PrivacyError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return data
        case 403:
            // Check if it's a parental consent error
            if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data),
               errorData.code == "PARENTAL_CONSENT_REQUIRED" {
                throw PrivacyError.parentalConsentRequired
            }
            throw PrivacyError.forbidden
        case 401:
            throw PrivacyError.unauthorized
        default:
            throw PrivacyError.serverError(httpResponse.statusCode)
        }
    }
    
    /// Delete all user data
    func deleteUserData() async throws {
        guard await authService.isSignedIn else {
            throw PrivacyError.notAuthenticated
        }
        
        guard let currentUser = await authService.currentUser else {
            throw PrivacyError.noUserData
        }
        
        // Get current ID token
        guard let idToken = try await authService.getCurrentIdToken() else {
            throw PrivacyError.noAuthToken
        }
        
        // Construct API URL
        guard let url = URL(string: "\(AppConstants.apiEndpoint)/users/\(currentUser.id)") else {
            throw PrivacyError.invalidURL
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        
        // Make request
        let (_, response) = try await URLSession.shared.data(for: request)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PrivacyError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200, 204:
            // Success - data deleted
            return
        case 403:
            throw PrivacyError.forbidden
        case 401:
            throw PrivacyError.unauthorized
        default:
            throw PrivacyError.serverError(httpResponse.statusCode)
        }
    }
}

// MARK: - Error Types

enum PrivacyError: LocalizedError {
    case notAuthenticated
    case noUserData
    case noAuthToken
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case parentalConsentRequired
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to perform this action"
        case .noUserData:
            return "No user data available"
        case .noAuthToken:
            return "Authentication token not available"
        case .invalidURL:
            return "Invalid server URL"
        case .invalidResponse:
            return "Invalid server response"
        case .unauthorized:
            return "You are not authorized to perform this action"
        case .forbidden:
            return "Access denied"
        case .parentalConsentRequired:
            return "This action requires parental consent"
        case .serverError(let code):
            return "Server error (code: \(code))"
        }
    }
}

// MARK: - Response Types

private struct ErrorResponse: Codable {
    let error: String
    let code: String?
}