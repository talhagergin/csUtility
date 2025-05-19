import SwiftUI
import SwiftData

@main
struct CS2LineupsApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(AppModelContainer.shared)
    }
}
