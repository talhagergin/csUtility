import SwiftUI
import SwiftData // Gerekirse

struct UserProfileView: View {
    @EnvironmentObject var viewModel: AccountViewModel
    @State private var showingSettings = false

    var body: some View {
        List { 
            Section {
                HStack {
                    Text("Kullanıcı Adı:")
                    Spacer()
                    Text(viewModel.loggedInUser?.username ?? "N/A")
                }
                
                if let lastLoginDate = viewModel.loggedInUser?.lastLogin {
                    HStack {
                        Text("Son Giriş:")
                        Spacer()
                        Text("\(lastLoginDate)")
                    }
                }
                
                if viewModel.isAdmin {
                    // Admin bilgisi zaten bir satır olarak görünecek,
                    // ayrı bir HStack'e gerek yok eğer sadece Text ise.
                    // Ancak vurgulamak için bir arka plan veya farklı font kullanılabilir.
                    Text("Yönetici Hesabı")
                        .font(.headline)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .center) // Satırda ortalamak için
                        // .listRowBackground(Color.green.opacity(0.1)) // Hafif bir arkaplan (opsiyonel)
                }
            } header: {
                Text("Kullanıcı Bilgileri")
            }
            
            Section {
                Button {
                    showingSettings = true
                } label: {
                    Label("Ayarlar", systemImage: "gear")
                }
                
                NavigationLink {
                    DownloadedVideosView()
                } label: {
                    Label("İndirilen Videolar", systemImage: "arrow.down.circle.fill")
                }
            } header: {
                Text("Uygulama")
            }
            
            if viewModel.isAdmin {
                Section {
                    NavigationLink("Haber Ekle/Yönet") {
                         AdminNewsManagementView() // Bu view'ın tanımlı olduğunu varsayıyoruz
                    }
                    // Buraya başka admin işlemleri için NavigationLink'ler eklenebilir
                    // Örneğin:
                    // NavigationLink("Kullanıcıları Yönet") { AdminUserManagementView() }
                } header: {
                    Text("Admin İşlemleri")
                }
            }

            // Çıkış Yap butonunu da bir Section içine alalım.
            Section {
                Button("Çıkış Yap", role: .destructive) {
                    viewModel.logout()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        // .navigationTitle("Hesabım") // Ana AccountView başlığı ayarladığı için burada gerek yok.
    }
}
