import Foundation

enum LineupCategory: String, CaseIterable, Identifiable, Codable {
    case aSite = "A Site"
    case bSite = "B Site"
    case mid = "Mid"
    case tSpawn = "T Spawn"
    case ctSpawn = "CT Spawn"
    case banana = "Banana" // Inferno örneği
    case longA = "Long A" // Dust II örneği
    case shortA = "Short A" // Dust II örneği
    case window = "Window" // Mirage örneği
    case connector = "Connector" // Mirage/Overpass örneği
    case general = "Genel" // Varsayılan veya kategorisizler için

    var id: String { self.rawValue }
    var displayName: String { self.rawValue }

    // İsterseniz her harita için farklı kategori setleri de tanımlayabilirsiniz,
    // ancak bu, yapıyı biraz daha karmaşıklaştırır. Şimdilik genel kategorilerle başlayalım.
}
