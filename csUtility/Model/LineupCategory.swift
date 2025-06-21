import Foundation

enum LineupCategory: String, CaseIterable, Identifiable, Codable {
    case aSite = "A Site"
    case bSite = "B Site"
    case mid = "Mid"
    case tSpawn = "T Spawn"
    case ctSpawn = "CT Spawn"
    case banana = "Banana"
    case longA = "Long A"
    case shortA = "Short A"
    case window = "Window"
    case connector = "Connector"
    case general = "Insta"

    var id: String { self.rawValue }
    var displayName: String { self.rawValue }
}
