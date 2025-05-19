import SwiftData
import Foundation

@Model
final class User {
    @Attribute(.unique) var username: String
    var hashedPassword: String // Gerçek uygulamada güvenli hash kullanılmalı
    var isAdmin: Bool
    var lastLogin: Date?

    init(username: String = "", hashedPassword: String = "", isAdmin: Bool = false, lastLogin: Date? = nil) {
        self.username = username
        self.hashedPassword = hashedPassword // DİKKAT: Bu sadece bir örnek, gerçekte güvenli hashing kullanın!
        self.isAdmin = isAdmin
        self.lastLogin = lastLogin
    }
}
