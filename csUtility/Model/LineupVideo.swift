import SwiftData
import SwiftUI

@Model
final class LineupVideo {
    @Attribute(.unique) var id: UUID
    var title: String
    var youtubeURL: String
    var mapName: String // CSMap.rawValue ile eşleşecek
    var utilityTypeRawValue: String // UtilityType.rawValue ile eşleşecek
    var uploadedDate: Date
    var uploaderID: String? // Admin kullanıcısının ID'si (opsiyonel)
    var localVideoPath: String? // İndirilen videonun cihazdaki yolu

    // Computed property for UtilityType
    var utilityType: UtilityType? {
        get { UtilityType(rawValue: utilityTypeRawValue) }
        set { utilityTypeRawValue = newValue?.rawValue ?? "" }
    }
    
    // Computed property for CSMap
    var map: CSMap? {
        get { CSMap(rawValue: mapName) }
        set { mapName = newValue?.rawValue ?? "" }
    }

    init(id: UUID = UUID(), title: String = "", youtubeURL: String = "", mapName: String = "", utilityType: UtilityType = .smoke, uploadedDate: Date = Date(), uploaderID: String? = nil, localVideoPath: String? = nil) {
        self.id = id
        self.title = title
        self.youtubeURL = youtubeURL
        self.mapName = mapName
        self.utilityTypeRawValue = utilityType.rawValue
        self.uploadedDate = uploadedDate
        self.uploaderID = uploaderID
        self.localVideoPath = localVideoPath
    }
}
