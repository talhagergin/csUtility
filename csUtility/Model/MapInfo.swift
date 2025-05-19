import SwiftUI // Image için

enum CSMap: String, CaseIterable, Identifiable {
    case dust2 = "Dust II"
    case mirage = "Mirage"
    case inferno = "Inferno"
    case overpass = "Overpass"
    case nuke = "Nuke"
    case vertigo = "Vertigo"
    case ancient = "Ancient"
    // case anubis = "Anubis" // CS2'de aktif harita havuzunda

    var id: String { self.rawValue }
    var imageName: String {
        switch self {
        case .dust2: return "map_dust2_image" // Assets'e eklenecek resim adı
        case .mirage: return "map_mirage_image"
        // ... Diğer haritalar
        default: return "map_placeholder_image"
        }
    }
    var displayName: String { self.rawValue }
}
