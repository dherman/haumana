//
//  ParentConsentStatus.swift
//  haumana
//
//  Created on 7/3/2025.
//

import Foundation

enum ParentConsentStatus: String, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case denied = "denied"
    
    var displayText: String {
        switch self {
        case .pending:
            return "Waiting for Parent Approval"
        case .approved:
            return "Parent Approved"
        case .denied:
            return "Parent Denied Access"
        }
    }
    
    var isApproved: Bool {
        return self == .approved
    }
}