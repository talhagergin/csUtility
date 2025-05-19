import SwiftUI
import SwiftData

@MainActor
class AccountViewModel: ObservableObject {
    @Published var loggedInUser: User?
    @Published var usernameInput: String = ""
    @Published var passwordInput: String = ""
    @Published var loginError: String?
    @Published var currentView: AccountSubView = .login // Veya .profile

    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        // Otomatik giriş için UserDefaults vs. kullanılabilir
        // checkAutoLogin()
    }

    func login() {
        loginError = nil
        let predicate = #Predicate<User> { user in
            user.username == usernameInput && user.hashedPassword == passwordInput // DİKKAT: Güvenli değil!
        }
        let descriptor = FetchDescriptor(predicate: predicate)

        do {
            let users = try modelContext.fetch(descriptor)
            if let user = users.first {
                loggedInUser = user
                user.lastLogin = Date()
                try? modelContext.save()
                currentView = .profile
                print("\(user.username) logged in. Admin: \(user.isAdmin)")
            } else {
                loginError = "Invalid username or password."
            }
        } catch {
            loginError = "Database error: \(error.localizedDescription)"
        }
    }

    func logout() {
        loggedInUser = nil
        usernameInput = ""
        passwordInput = ""
        currentView = .login
    }
    
    var isAdmin: Bool {
        loggedInUser?.isAdmin ?? false
    }
    
    enum AccountSubView {
        case login, profile
    }
}
