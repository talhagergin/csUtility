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

    /// YouTube thumbnail URL'si (hqdefault)
    var youtubeThumbnailURL: URL? {
        guard let videoID = Self.extractYouTubeVideoID(from: youtubeURL) else { return nil }
        return URL(string: "https://img.youtube.com/vi/\(videoID)/hqdefault.jpg")
    }
    
    /// YouTube video ID'sini URL'den çıkarır
    static func extractYouTubeVideoID(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        if url.host?.contains("youtu.be") == true {
            return url.lastPathComponent
        }
        if url.path.contains("/embed/") {
            return url.lastPathComponent
        }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        return components?.queryItems?.first(where: { $0.name == "v" })?.value
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
