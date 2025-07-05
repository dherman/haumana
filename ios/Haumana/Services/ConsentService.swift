//
//  ConsentService.swift
//  haumana
//
//  Created on 7/3/2025.
//

import Foundation
import SwiftData

/// Service for managing parental consent status
@MainActor
class ConsentService: ObservableObject {
    @Published var consentStatus: ParentConsentStatus = .pending
    @Published var isLoading = false
    @Published var error: Error?
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Checks the current consent status from DynamoDB via API
    func checkConsentStatus(for user: User) async {
        let userId = user.id
        
        isLoading = true
        error = nil
        
        do {
            // Call our API to check DynamoDB for consent status
            let status = try await fetchConsentStatusFromAPI(userId: userId)
            
            // Update local user model
            user.parentConsentStatus = status.rawValue
            if status == .approved {
                user.parentConsentDate = Date()
            }
            
            // Save to local database
            try modelContext.save()
            
            // Update published property
            self.consentStatus = status
            
        } catch {
            self.error = error
            print("Error checking consent status: \(error)")
        }
        
        isLoading = false
    }
    
    /// Fetches consent status from our API (which reads from DynamoDB)
    private func fetchConsentStatusFromAPI(userId: String) async throws -> ParentConsentStatus {
        // Use the API endpoint from AppConstants
        let apiEndpoint = AppConstants.apiEndpoint
        
        let url = URL(string: "\(apiEndpoint)/users/\(userId)/consent-status")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authentication header if we have a token
        // Note: In a real implementation, you would pass the token from the auth service
        // For now, we'll skip authentication on this endpoint
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ConsentError.apiError
        }
        
        struct ConsentResponse: Codable {
            let status: String
            let parentEmail: String?
            let approvedAt: String?
        }
        
        let consentResponse = try JSONDecoder().decode(ConsentResponse.self, from: data)
        
        return ParentConsentStatus(rawValue: consentResponse.status) ?? .pending
    }
    
    /// Requests parent consent through KWS
    func requestParentConsent(for user: User, parentEmail: String) async throws {
        isLoading = true
        error = nil
        
        defer {
            isLoading = false
        }
        
        do {
            // First, create KWS user if needed
            if user.kwsUserId == nil {
                let kwsUserId = try await KWSAPIClient.shared.createUser(
                    birthdate: user.birthdate ?? Date(),
                    email: user.email
                )
                user.kwsUserId = kwsUserId
            }
            
            // Request parent consent
            guard let kwsUserId = user.kwsUserId else {
                throw ConsentError.missingKWSUserId
            }
            
            _ = try await KWSAPIClient.shared.requestParentConsent(
                userId: kwsUserId,
                parentEmail: parentEmail
            )
            
            // Update local status
            user.parentConsentStatus = ParentConsentStatus.pending.rawValue
            user.parentEmail = parentEmail
            
            try modelContext.save()
            
            self.consentStatus = .pending
            
        } catch {
            self.error = error
            throw error
        }
    }
    
    enum ConsentError: LocalizedError {
        case missingAPIEndpoint
        case apiError
        case missingKWSUserId
        
        var errorDescription: String? {
            switch self {
            case .missingAPIEndpoint:
                return "API endpoint not configured"
            case .apiError:
                return "Failed to fetch consent status"
            case .missingKWSUserId:
                return "KWS user ID not found"
            }
        }
    }
}