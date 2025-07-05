import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: String
    var email: String
    var displayName: String?
    var photoUrl: String?
    var createdAt: Date
    var lastLoginAt: Date
    var birthdate: Date?
    var isMinor: Bool = false
    
    // KWS Integration
    var kwsUserId: String?
    var parentConsentStatus: String? // "pending", "approved", "denied"
    var parentEmail: String?
    var parentConsentDate: Date?
    
    init(id: String, email: String, displayName: String? = nil, photoUrl: String? = nil, birthdate: Date? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoUrl = photoUrl
        self.birthdate = birthdate
        self.createdAt = Date()
        self.lastLoginAt = Date()
        
        // Calculate if user is a minor based on birthdate
        if let birthdate = birthdate {
            let calendar = Calendar.current
            let ageComponents = calendar.dateComponents([.year], from: birthdate, to: Date())
            self.isMinor = (ageComponents.year ?? 0) < 13
        }
    }
}