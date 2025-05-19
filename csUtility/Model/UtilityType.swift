import SwiftUI

enum UtilityType: String, CaseIterable, Identifiable, Codable {
    case smoke = "Smoke"
    case molotov = "Molotov" // Incendiary Grenade için de kullanılabilir
    case flash = "Flashbang"
    case hegrenade = "HE Grenade" // Nade olarak kısaltılmıştı, tam adını kullanmak daha iyi olabilir

    var id: String { self.rawValue }
    var iconName: String { // SF Symbols veya özel ikonlar için
        switch self {
        case .smoke: return "smoke.fill" // Örnek SF Symbol
        case .molotov: return "flame.fill"
        case .flash: return "bolt.fill"
        case .hegrenade: return "circle.grid.3x3.fill" // Daha iyi bir ikon bulunabilir
        }
    }
}
