//
//  KWSAPIClient.swift
//  haumana
//
//  Created on 7/3/2025.
//

import Foundation

/// Client for interacting with Kids Web Services (KWS) API
@MainActor
class KWSAPIClient: ObservableObject {
    static let shared = KWSAPIClient()
    
    // KWS API Configuration
    private let baseURL = "https://api.kws.superawesome.com/v2" // Update with actual KWS API URL
    private let appId: String
    private let apiKey: String
    
    // Error types
    enum KWSError: LocalizedError {
        case invalidURL
        case noData
        case decodingError
        case serverError(String)
        case unauthorized
        case networkError(Error)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL configuration"
            case .noData:
                return "No data received from server"
            case .decodingError:
                return "Failed to decode server response"
            case .serverError(let message):
                return "Server error: \(message)"
            case .unauthorized:
                return "Unauthorized - check API credentials"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            }
        }
    }
    
    // Response models
    struct CreateUserResponse: Codable {
        let userId: String
        let status: String
    }
    
    struct RequestConsentResponse: Codable {
        let requestId: String
        let status: String
        let message: String?
    }
    
    struct ConsentStatus: Codable {
        let userId: String
        let status: String // "pending", "approved", "denied"
        let permissions: [String]?
        let parentEmail: String?
        let approvedAt: String?
    }
    
    // Test mode for development - set via launch argument or debug menu
    var isTestMode: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-testKWS") || 
               UserDefaults.standard.bool(forKey: "testKWSMode")
        #else
        return false
        #endif
    }
    
    private init() {
        // Load API credentials from Info.plist or configuration
        // For now, using placeholders - these should be stored securely
        self.appId = ProcessInfo.processInfo.environment["KWS_APP_ID"] ?? "YOUR_KWS_APP_ID"
        self.apiKey = ProcessInfo.processInfo.environment["KWS_API_KEY"] ?? "YOUR_KWS_API_KEY"
    }
    
    /// Creates a new user in KWS
    /// - Parameters:
    ///   - birthdate: User's birthdate for age verification
    ///   - email: User's email (from Google sign-in)
    /// - Returns: KWS user ID
    func createUser(birthdate: Date, email: String) async throws -> String {
        // Test mode: return a fake user ID
        if isTestMode {
            print("🧪 TEST MODE: Creating fake KWS user")
            // Simulate network delay
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            return "test_user_\(UUID().uuidString)"
        }
        
        let endpoint = "\(baseURL)/apps/\(appId)/users"
        
        guard let url = URL(string: endpoint) else {
            throw KWSError.invalidURL
        }
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        
        let body: [String: Any] = [
            "email": email,
            "birthdate": dateFormatter.string(from: birthdate),
            "source": "ios_app"
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw KWSError.serverError("Invalid response")
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                let createResponse = try JSONDecoder().decode(CreateUserResponse.self, from: data)
                return createResponse.userId
            case 401:
                throw KWSError.unauthorized
            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw KWSError.serverError(errorMessage)
            }
        } catch let error as KWSError {
            throw error
        } catch {
            throw KWSError.networkError(error)
        }
    }
    
    /// Requests parental consent for a user
    /// - Parameters:
    ///   - userId: KWS user ID
    ///   - parentEmail: Parent's email address
    /// - Returns: Request ID for tracking
    func requestParentConsent(userId: String, parentEmail: String) async throws -> String {
        // Test mode: return a fake request ID and store for testing
        if isTestMode {
            print("🧪 TEST MODE: Creating fake consent request for parent: \(parentEmail)")
            // Simulate network delay
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Store test data for manual approval simulation
            UserDefaults.standard.set(userId, forKey: "testKWS_userId")
            UserDefaults.standard.set(parentEmail, forKey: "testKWS_parentEmail")
            UserDefaults.standard.set("pending", forKey: "testKWS_consentStatus")
            
            return "test_request_\(UUID().uuidString)"
        }
        
        let endpoint = "\(baseURL)/apps/\(appId)/users/\(userId)/request-permissions"
        
        guard let url = URL(string: endpoint) else {
            throw KWSError.invalidURL
        }
        
        let body: [String: Any] = [
            "parentEmail": parentEmail,
            "permissions": ["personal_info", "data_collection"],
            "language": "en"
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw KWSError.serverError("Invalid response")
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                let consentResponse = try JSONDecoder().decode(RequestConsentResponse.self, from: data)
                return consentResponse.requestId
            case 401:
                throw KWSError.unauthorized
            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw KWSError.serverError(errorMessage)
            }
        } catch let error as KWSError {
            throw error
        } catch {
            throw KWSError.networkError(error)
        }
    }
}