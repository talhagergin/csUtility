import SwiftData
import Foundation // Belki UUID vs. için, ama burada doğrudan gerekmeyebilir.

public actor AppModelContainer {
    @MainActor
    public static let shared: ModelContainer = {
        let schema = Schema([
            LineupVideo.self,
            User.self,
            NewsItem.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // iOS 17+ için #Predicate kullanımı
            // Örnek admin kullanıcısı ekleme (ilk çalıştırmada)
            // Gerçek uygulamada bu daha kontrollü yapılmalı
            let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.username == "admin" }) // BU SATIRDA HATA ALIYORSANIZ
            
            // iOS 16 ve öncesi için (Eğer eski sürümü desteklemeniz gerekiyorsa)
            // let predicate = NSPredicate(format: "username == %@", "admin")
            // let descriptor = FetchDescriptor<User>(predicate: predicate)

            if try container.mainContext.fetchCount(descriptor) == 0 {
                let adminUser = User(username: "admin", hashedPassword: "adminpassword", isAdmin: true) // Güvenli hash kullanın!
                container.mainContext.insert(adminUser)
                try? container.mainContext.save()
                print("Admin user created.")
            }
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
