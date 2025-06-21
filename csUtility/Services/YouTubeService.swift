import Foundation

enum YouTubeServiceError: Error {
    case invalidAPIKey
    case invalidVideoID
    case networkError(Error)
    case noVideoFound
    case quotaExceeded
    case unknown
}

class YouTubeService {
    // YouTube Data API v3 key - Google Cloud Console'dan alınmalı
    private let apiKey = "YOUR_YOUTUBE_API_KEY" // Buraya gerçek API key'inizi ekleyin
    
    // Video bilgilerini al
    func fetchVideoInfo(videoID: String) async throws -> YouTubeVideoInfo {
        guard !apiKey.isEmpty && apiKey != "YOUR_YOUTUBE_API_KEY" else {
            throw YouTubeServiceError.invalidAPIKey
        }
        
        let urlString = "https://www.googleapis.com/youtube/v3/videos?part=snippet,contentDetails,statistics&id=\(videoID)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw YouTubeServiceError.invalidVideoID
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw YouTubeServiceError.unknown
            }
            
            if httpResponse.statusCode == 403 {
                throw YouTubeServiceError.quotaExceeded
            }
            
            if httpResponse.statusCode != 200 {
                throw YouTubeServiceError.unknown
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            guard let items = json?["items"] as? [[String: Any]],
                  let firstItem = items.first,
                  let snippet = firstItem["snippet"] as? [String: Any] else {
                throw YouTubeServiceError.noVideoFound
            }
            
            let title = snippet["title"] as? String ?? "Unknown Title"
            let description = snippet["description"] as? String ?? ""
            let channelTitle = snippet["channelTitle"] as? String ?? "Unknown Channel"
            let publishedAt = snippet["publishedAt"] as? String ?? ""
            let thumbnails = snippet["thumbnails"] as? [String: Any] ?? [:]
            
            // Thumbnail URL'lerini al
            let thumbnailURLs = extractThumbnailURLs(from: thumbnails)
            
            return YouTubeVideoInfo(
                id: videoID,
                title: title,
                description: description,
                channelTitle: channelTitle,
                publishedAt: publishedAt,
                thumbnailURLs: thumbnailURLs
            )
            
        } catch {
            if error is YouTubeServiceError {
                throw error
            }
            throw YouTubeServiceError.networkError(error)
        }
    }
    
    // Thumbnail URL'lerini çıkar
    private func extractThumbnailURLs(from thumbnails: [String: Any]) -> [String: String] {
        var urls: [String: String] = [:]
        
        if let defaultThumb = thumbnails["default"] as? [String: Any],
           let defaultURL = defaultThumb["url"] as? String {
            urls["default"] = defaultURL
        }
        
        if let mediumThumb = thumbnails["medium"] as? [String: Any],
           let mediumURL = mediumThumb["url"] as? String {
            urls["medium"] = mediumURL
        }
        
        if let highThumb = thumbnails["high"] as? [String: Any],
           let highURL = highThumb["url"] as? String {
            urls["high"] = highURL
        }
        
        if let standardThumb = thumbnails["standard"] as? [String: Any],
           let standardURL = standardThumb["url"] as? String {
            urls["standard"] = standardURL
        }
        
        return urls
    }
    
    // YouTube video ID'sini URL'den çıkar
    func extractVideoID(from urlString: String) -> String? {
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
    
    // YouTube'da açma URL'i oluştur
    func createYouTubeURL(videoID: String) -> URL? {
        return URL(string: "https://www.youtube.com/watch?v=\(videoID)")
    }
    
    // YouTube uygulamasında açma URL'i oluştur (iOS)
    func createYouTubeAppURL(videoID: String) -> URL? {
        return URL(string: "youtube://\(videoID)")
    }
}

// Video bilgileri için model
struct YouTubeVideoInfo {
    let id: String
    let title: String
    let description: String
    let channelTitle: String
    let publishedAt: String
    let thumbnailURLs: [String: String]
    
    var bestThumbnailURL: String? {
        return thumbnailURLs["high"] ?? thumbnailURLs["standard"] ?? thumbnailURLs["medium"] ?? thumbnailURLs["default"]
    }
} 