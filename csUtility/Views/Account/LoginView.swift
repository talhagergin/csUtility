import SwiftUI
import Foundation
import SwiftData

struct LoginView: View {
    @EnvironmentObject var viewModel: AccountViewModel

    var body: some View {
        Form {
            Section {
                TextField("Kullanıcı Adı", text: $viewModel.usernameInput)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                SecureField("Şifre", text: $viewModel.passwordInput)
            } header: {
                Text("Giriş Bilgileri")
            }

            if let error = viewModel.loginError {
                Section { // Hata mesajını bir Section içine al
                    Text(error)
                        .foregroundColor(.red)
                }
                // .listRowSeparator(.hidden) // Bu modifier Section için farklı çalışabilir veya gereksiz olabilir.
                                          // Gerekirse Section'a .listRowInsets(EdgeInsets()) ekleyebilirsiniz.
            }

            Section { // Butonu da bir Section içine almayı deneyin
                Button("Giriş Yap") {
                    viewModel.login()
                }
                .frame(maxWidth: .infinity, alignment: .center) // Butonun Section içinde ortalanması
            }
        }
    }
}
