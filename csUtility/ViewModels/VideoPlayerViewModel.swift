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
        print("🔍 DEBUG: VideoPlayerViewModel init - video: \(video.title)")
        print("🔍 DEBUG: - localVideoPath: \(video.localVideoPath ?? "nil")")
        checkLocalVideoStatus() // video'nun mevcut durumuna göre canPlayLocalVideo'yu ayarla
    }

    func extractYouTubeVideoID(from urlString: String) -> String? {
        print("🔍 DEBUG: YouTube URL parse ediliyor: \(urlString)")
        
        guard let url = URL(string: urlString) else { 
            print("❌ DEBUG: Geçersiz URL formatı")
            return nil 
        }

        if url.host?.contains("youtu.be") == true {
            let videoID = url.lastPathComponent
            print("🔍 DEBUG: youtu.be formatı - Video ID: \(videoID)")
            return videoID
        }

        if url.path.contains("/embed/") {
            let videoID = url.lastPathComponent
            print("🔍 DEBUG: embed formatı - Video ID: \(videoID)")
            return videoID
        }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let videoID = components?.queryItems?.first(where: { $0.name == "v" })?.value {
            print("🔍 DEBUG: youtube.com formatı - Video ID: \(videoID)")
            return videoID
        }
        
        print("❌ DEBUG: Video ID bulunamadı")
        return nil
    }

    func downloadVideo(context: ModelContext) async {
        print("🔍 DEBUG: downloadVideo başladı")
        print("🔍 DEBUG: video.title: \(video.title)")
        print("🔍 DEBUG: video.youtubeURL: \(video.youtubeURL)")
        
        guard let videoID = extractYouTubeVideoID(from: video.youtubeURL) else {
            downloadError = "Geçersiz YouTube URL'si"
            print("❌ DEBUG: Geçersiz YouTube URL'si")
            return
        }
        
        isDownloading = true
        downloadError = nil
        downloadProgress = 0.0

        print("🔍 DEBUG: VideoDownloadService.downloadVideo çağrılıyor")

        // VideoDownloadService kullanarak gerçek video indirme
        downloadService.downloadVideo(
            youtubeURL: video.youtubeURL,
            progressHandler: { progress in
                Task { @MainActor in
                    self.downloadProgress = progress
                    print("🔍 DEBUG: İndirme progress: \(Int(progress * 100))%")
                }
            },
            completion: { result in
                Task { @MainActor in
                    switch result {
                    case .success(let localURL):
                        print("🔍 DEBUG: Video indirme başarılı")
                        print("🔍 DEBUG: localURL: \(localURL)")
                        print("🔍 DEBUG: localURL.path: \(localURL.path)")
                        
                        // Video path'ini kaydet
                        self.video.localVideoPath = localURL.path
                        print("🔍 DEBUG: video.localVideoPath ayarlandı: \(self.video.localVideoPath ?? "nil")")
                        
                        do {
                            try context.save()
                            print("🔍 DEBUG: Context kaydedildi")
                            self.checkLocalVideoStatus()
                            print("🔍 DEBUG: checkLocalVideoStatus çağrıldı")
                            print("🔍 DEBUG: canPlayLocalVideo: \(self.canPlayLocalVideo)")
                            print("Video download complete. Path: \(self.video.localVideoPath ?? "N/A")")
                        } catch {
                            print("❌ DEBUG: Context kaydetme hatası: \(error)")
                            self.downloadError = "Video kaydetme hatası: \(error.localizedDescription)"
                        }
                    case .failure(let error):
                        print("❌ DEBUG: Video indirme hatası: \(error)")
                        self.downloadError = "Video indirme hatası: \(error.localizedDescription)"
                        print("Download error: \(error)")
                    }
                    self.isDownloading = false
                }
            }
        )
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
        print("🔍 DEBUG: deleteDownloadedVideo çağrıldı")
        guard let path = video.localVideoPath, !path.isEmpty else { 
            print("❌ DEBUG: localVideoPath yok veya boş")
            return 
        }
        
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
        print("🔍 DEBUG: checkLocalVideoStatus çağrıldı")
        print("🔍 DEBUG: video.localVideoPath: \(video.localVideoPath ?? "nil")")
        
        if let path = video.localVideoPath, !path.isEmpty {
            let fileExists = FileManager.default.fileExists(atPath: path)
            print("🔍 DEBUG: Dosya var mı: \(fileExists)")
            
            if fileExists {
                do {
                    let attributes = try FileManager.default.attributesOfItem(atPath: path)
                    let fileSize = attributes[.size] as? Int64 ?? 0
                    print("🔍 DEBUG: Dosya boyutu: \(fileSize) bytes")
                    
                    if fileSize > 0 {
                        canPlayLocalVideo = true
                        print("🔍 DEBUG: canPlayLocalVideo = true")
                    } else {
                        canPlayLocalVideo = false
                        print("🔍 DEBUG: Dosya boş, canPlayLocalVideo = false")
                    }
                } catch {
                    print("🔍 DEBUG: Dosya özellikleri alınamadı: \(error)")
                    canPlayLocalVideo = false
                }
            } else {
                canPlayLocalVideo = false
                print("🔍 DEBUG: Dosya bulunamadı, canPlayLocalVideo = false")
            }
        } else {
            canPlayLocalVideo = false
            print("🔍 DEBUG: localVideoPath yok veya boş, canPlayLocalVideo = false")
        }
    }
}
