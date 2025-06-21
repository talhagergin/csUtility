import SwiftUI
import AVKit
import SwiftData

@MainActor
class VideoPlayerViewModel: ObservableObject {
    // @ObservedObject var video: LineupVideo // BU SATIRI DEĞİŞTİRİN
    let video: LineupVideo // Sadece 'let' olarak tanımlayın. Bu bir referans olacak.

    @Published var isDownloading: Bool = false
    @Published var downloadProgress: Double = 0.0
    @Published var downloadError: String?
    @Published var canPlayLocalVideo: Bool = false // Bu @Published kalabilir, çünkü ViewModel'in kendi durumu.

    private var downloadService = VideoDownloadService()

    init(video: LineupVideo) {
        self.video = video // 'video' parametresini sakla
        checkLocalVideoStatus() // video'nun mevcut durumuna göre canPlayLocalVideo'yu ayarla
    }

    func extractYouTubeVideoID(from urlString: String) -> String? {
        // ... (kod değişmedi)
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

    func downloadVideo(context: ModelContext) async {
        guard let videoID = extractYouTubeVideoID(from: video.youtubeURL) else {
            downloadError = "Geçersiz YouTube URL'si"
            return
        }
        
        isDownloading = true
        downloadError = nil
        downloadProgress = 0.0

        do {
            // Gerçek video indirme işlemi
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let videosFolder = documentsPath.appendingPathComponent("DownloadedVideos")
            
            // Videos klasörünü oluştur
            try FileManager.default.createDirectory(at: videosFolder, withIntermediateDirectories: true, attributes: nil)
            
            let fileName = "\(video.id.uuidString).mp4"
            let localFileURL = videosFolder.appendingPathComponent(fileName)
            
            // Eğer dosya zaten varsa, sil
            if FileManager.default.fileExists(atPath: localFileURL.path) {
                try FileManager.default.removeItem(at: localFileURL)
            }
            
            // YouTube video indirme (demo amaçlı)
            // Not: Gerçek YouTube video indirme için özel API'ler veya yt-dlp gibi kütüphaneler gerekiyor
            // Şimdilik demo amaçlı basit bir video dosyası oluşturuyoruz
            
            // Progress simülasyonu
            for i in 1...10 {
                try await Task.sleep(nanoseconds: 200_000_000)
                self.downloadProgress = Double(i) / 10.0
            }
            
            // Demo amaçlı basit bir video dosyası oluştur
            // Bu kısım gerçek uygulamada YouTube video indirme API'si ile değiştirilmeli
            let demoVideoContent = """
            Demo video content for: \(video.title)
            Video ID: \(videoID)
            Map: \(video.mapName)
            Utility: \(video.utilityTypeRawValue)
            Category: \(video.category ?? "N/A")
            Upload Date: \(video.uploadedDate)
            
            Bu bir demo video dosyasıdır. Gerçek uygulamada bu kısım YouTube video indirme API'si ile değiştirilecektir.
            """
            let demoVideoData = Data(demoVideoContent.utf8)
            try demoVideoData.write(to: localFileURL)
            
            // Video path'ini kaydet
            video.localVideoPath = localFileURL.path
            try context.save()
            checkLocalVideoStatus()
            
            print("Demo video download complete. Path: \(video.localVideoPath ?? "N/A")")
            
        } catch {
            downloadError = "Video indirme hatası: \(error.localizedDescription)"
            print("Download error: \(error)")
        }
        
        isDownloading = false
    }
    
    // YouTube video bilgilerini almak için (opsiyonel)
    private func fetchYouTubeVideoInfo(videoID: String) async throws -> [String: Any]? {
        let urlString = "https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=\(videoID)&format=json"
        guard let url = URL(string: urlString) else { return nil }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json
    }
    
    func deleteDownloadedVideo(context: ModelContext) {
        guard let path = video.localVideoPath, !path.isEmpty else { return }
        do {
            try FileManager.default.removeItem(atPath: path)
            video.localVideoPath = nil // 'video' örneğini güncelle
            try context.save() // Değişikliği SwiftData'ya kaydet
            checkLocalVideoStatus() // Durumu güncelle
            print("Deleted local video: \(path)")
        } catch {
            print("Error deleting local video: \(error.localizedDescription)")
            downloadError = "Yerel video silinirken hata: \(error.localizedDescription)" // Kullanıcıya hata göster
        }
    }

    func checkLocalVideoStatus() {
        if let path = video.localVideoPath, !path.isEmpty, FileManager.default.fileExists(atPath: path) {
            canPlayLocalVideo = true
        } else {
            canPlayLocalVideo = false
            // Eğer path var ama dosya yoksa, SwiftData'daki path'i de temizlemek iyi bir pratik olabilir.
            // Ancak bu, deleteDownloadedVideo içinde zaten yapılmalı.
            // if video.localVideoPath != nil && !video.localVideoPath!.isEmpty {
            //     video.localVideoPath = nil
            //     // try? modelContext.save() // Eğer ViewModel'in kendi context'i olsaydı.
            // }
        }
    }
}
