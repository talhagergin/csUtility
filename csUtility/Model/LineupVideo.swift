// Models/LineupVideo.swift
import SwiftData
import SwiftUI

@Model
final class LineupVideo {
    @Attribute(.unique) var id: UUID
    var title: String
    var youtubeURL: String
    var mapName: String
    var utilityTypeRawValue: String
    var category: String? // YENİ: Kategori alanı (opsiyonel yaptık, eski videolar için)
    var uploadedDate: Date
    var uploaderID: String?
    var localVideoPath: String?

    var utilityType: UtilityType? {
        get { UtilityType(rawValue: utilityTypeRawValue) }
        set { utilityTypeRawValue = newValue?.rawValue ?? "" }
    }
    
    var map: CSMap? {
        get { CSMap(rawValue: mapName) }
        set { mapName = newValue?.rawValue ?? "" }
    }

    init(id: UUID = UUID(), title: String = "", youtubeURL: String = "", mapName: String = "", utilityType: UtilityType = .smoke, category: String? = nil, uploadedDate: Date = Date(), uploaderID: String? = nil, localVideoPath: String? = nil) {
        self.id = id
        self.title = title
        self.youtubeURL = youtubeURL
        self.mapName = mapName
        self.utilityTypeRawValue = utilityType.rawValue
        self.category = category // YENİ
        self.uploadedDate = uploadedDate
        self.uploaderID = uploaderID
        self.localVideoPath = localVideoPath
    }
}
