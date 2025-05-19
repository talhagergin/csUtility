// AccountView.swift

import SwiftUI
import SwiftData // Gerekirse

struct AccountView: View {
    @EnvironmentObject var viewModel: AccountViewModel
    // @Environment(\.modelContext) private var modelContext // Bu view'da doğrudan kullanılmıyorsa kaldırılabilir

    var body: some View {
        VStack { // Veya NavigationView/NavigationStack
            if viewModel.loggedInUser == nil {
                LoginView()
            } else {
                UserProfileView()
            }
        }
        .navigationTitle(viewModel.loggedInUser == nil ? "Giriş Yap" : "Hesabım")
        // .environmentObject(viewModel) // MainTabView'de zaten set edildi
    }
}


// Placeholder for Admin News Management (bu zaten vardı)
struct AdminNewsManagementView: View {
    var body: some View {
        Text("Admin Haber Yönetim Paneli (Yapım Aşamasında)")
            //.navigationTitle("Haber Yönetimi")
    }
}
