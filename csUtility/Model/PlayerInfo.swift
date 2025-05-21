import Foundation

struct PlayerInfo: Codable, Identifiable, Hashable {
    var id: UUID // Her oyuncu için benzersiz ID (Codable için)
    let playerName: String
    let countryCode: String // İki harfli ülke kodu (örn: "TR", "DK", "FR")

    // Varsayılan değerlerle initializer
    init(id: UUID = UUID(), playerName: String, countryCode: String) {
        self.id = id
        self.playerName = playerName
        self.countryCode = countryCode
    }
}
