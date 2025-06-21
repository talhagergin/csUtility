import SwiftUI // Image için

enum CSMap: String, CaseIterable, Identifiable {
    case dust2 = "Dust II"
    case mirage = "Mirage"
    case inferno = "Inferno"
    case train = "Train"
    case nuke = "Nuke"
    case anubis = "Anubis"
    case ancient = "Ancient"
    // case anubis = "Anubis" // CS2'de aktif harita havuzunda

    var id: String { self.rawValue }
    var imageName: String {
        switch self {
        case .dust2: return "dust2cs2" // Assets'e eklenecek resim adı
        case .mirage: return "miragecs2"
        case .inferno: return "infernocs2"
        case .nuke: return "nukecs2"
        case .ancient: return "ancientcs2"
        case .train: return "traincs2"
        case .anubis: return "anubiscs2"
        // ... Diğer haritalar
        default: return "map_placeholder_image"
        }
    }
    var displayName: String { self.rawValue }
}
