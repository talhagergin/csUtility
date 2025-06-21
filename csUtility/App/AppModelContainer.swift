// AppModelContainer.swift
import SwiftData
import Foundation

public actor AppModelContainer {
    @MainActor
    public static let shared: ModelContainer = {
        let schema = Schema([
            LineupVideo.self,
            User.self,
            NewsItem.self,
            TeamRanking.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            let context = container.mainContext // ModelContext'i al

            // 1. Başlangıç Admin Kullanıcısını Oluştur (Eğer yoksa)
            let adminDescriptor = FetchDescriptor<User>(predicate: #Predicate { $0.username == "admin" })
            if try context.fetchCount(adminDescriptor) == 0 {
                let adminUser = User(username: "admin", hashedPassword: "adminpassword", isAdmin: true)
                context.insert(adminUser)
                print("Admin user 'admin' will be created if it doesn't exist.")
            }

            // 2. DİĞER BAŞLANGIÇ VERİLERİNİ YÜKLE (JSON'dan)
            // seedInitialData fonksiyonu burada çağrılıyor.
            // Bu fonksiyon hem lineup'ları hem de takım sıralamalarını yükleyecek.
            seedInitialData(modelContext: context)

            // 3. Yapılan tüm değişiklikleri kaydet
            if context.hasChanges {
                do {
                    try context.save()
                    print("Successfully saved changes to ModelContainer (admin/seed data).")
                } catch {
                    print("ERROR: Could not save initial data to ModelContainer: \(error.localizedDescription)")
                }
            } else {
                print("No changes to save in ModelContainer after initial setup (admin exists, data already seeded).")
            }
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
