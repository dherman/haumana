//
//  KeychainService.swift
//  haumana
//
//  Created on 7/2/2025.
//

import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    
    private let birthdateKey = "app.haumana.user.birthdate"
    
    private init() {}
    
    func saveBirthdate(_ date: Date, for userId: String) throws {
        let key = "\(birthdateKey).\(userId)"
        let data = try JSONEncoder().encode(date)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "app.haumana",
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // First try to delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Then add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            throw KeychainError.unableToSave
        }
    }
    
    func getBirthdate(for userId: String) throws -> Date? {
        let key = "\(birthdateKey).\(userId)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "app.haumana",
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            throw KeychainError.unableToRetrieve
        }
        
        return try JSONDecoder().decode(Date.self, from: data)
    }
    
    func deleteBirthdate(for userId: String) throws {
        let key = "\(birthdateKey).\(userId)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "app.haumana",
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unableToDelete
        }
    }
}

enum KeychainError: LocalizedError {
    case unableToSave
    case unableToRetrieve
    case unableToDelete
    
    var errorDescription: String? {
        switch self {
        case .unableToSave:
            return "Unable to save data to keychain"
        case .unableToRetrieve:
            return "Unable to retrieve data from keychain"
        case .unableToDelete:
            return "Unable to delete data from keychain"
        }
    }
}