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
    
    init(id: String, email: String, displayName: String? = nil, photoUrl: String? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoUrl = photoUrl
        self.createdAt = Date()
        self.lastLoginAt = Date()
    }
}