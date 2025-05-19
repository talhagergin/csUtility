import SwiftUI

struct MainTabView: View {
    @StateObject private var accountViewModel: AccountViewModel
    @Environment(\.modelContext) private var modelContext

    init() {
        // AccountViewModel'i burada başlatıyoruz, böylece tüm tab'lar aynı instance'ı kullanabilir.
        // _accountViewModel, @StateObject'in private storage'ına erişim sağlar.
        _accountViewModel = StateObject(wrappedValue: AccountViewModel(modelContext: AppModelContainer.shared.mainContext))
    }
    
    var body: some View {
        TabView {
            NavigationStack {
                MapsListView(viewModel: MapsViewModel())
            }
            .tabItem {
                Label("Haritalar", systemImage: "map.fill")
            }

            NavigationStack {
                NewsListView(modelContext: modelContext) // Veya kendi ViewModel'i
            }
            .tabItem {
                Label("Haberler", systemImage: "newspaper.fill")
            }

            NavigationStack {
                AccountView()
            }
            .tabItem {
                Label("Hesabım", systemImage: "person.crop.circle.fill")
            }
        }
        .environmentObject(accountViewModel) // AccountViewModel'i environment'a ekliyoruz
    }
}
