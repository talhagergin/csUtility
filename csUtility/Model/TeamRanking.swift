// Models/TeamRanking.swift (Yeni dosya)
import SwiftData
import SwiftUI // Color için gerekebilir

@Model
final class TeamRanking {
    @Attribute(.unique) var id: UUID // Takımın veya o anki sıralama kaydının ID'si
    var rank: Int
    var teamName: String
    var points: Int
    var players: [PlayerInfo] // Oyuncu bilgilerini içeren dizi
    var logoName: String? // Takım logosu için Assets'teki resim adı (opsiyonel)
    var rankChange: Int?  // Sıralama değişimi (+1, -1, 0 veya nil)
    var lastUpdated: Date // Bu sıralama bilgisinin son güncellenme tarihi

    init(id: UUID = UUID(), rank: Int, teamName: String, points: Int, players: [PlayerInfo] = [], logoName: String? = nil, rankChange: Int? = nil, lastUpdated: Date = Date()) {
        self.id = id
        self.rank = rank
        self.teamName = teamName
        self.points = points
        self.players = players
        self.logoName = logoName
        self.rankChange = rankChange
        self.lastUpdated = lastUpdated
    }

    // Sıralama değişimi için görselleştirme (opsiyonel)
    var rankChangeDisplay: (text: String, color: Color) {
        guard let change = rankChange else { return ("", .gray) }
        if change > 0 {
            return ("+\(change)", .green)
        } else if change < 0 {
            return ("\(change)", .red)
        } else {
            return ("-", .gray) // Değişim yok ama belirtmek için
        }
    }
}
