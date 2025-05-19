import SwiftData
import Foundation

@Model
final class NewsItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var content: String
    var publishedDate: Date
    var author: String?
    var imageURL: String?

    init(id: UUID = UUID(), title: String = "", content: String = "", publishedDate: Date = Date(), author: String? = "Admin", imageURL: String? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.publishedDate = publishedDate
        self.author = author
        self.imageURL = imageURL
    }
}
