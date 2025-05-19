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

        // ----- Simülasyon Başlangıcı -----
        print("Simulating download for video ID: \(videoID)")
        do {
            for i in 1...10 {
                try await Task.sleep(nanoseconds: 300_000_000)
                self.downloadProgress = Double(i) / 10.0
            }
            
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "\(video.id.uuidString).mp4"
            let localFileURL = tempDir.appendingPathComponent(fileName)
            
            FileManager.default.createFile(atPath: localFileURL.path, contents: Data(), attributes: nil)
            
            // ÖNEMLİ: 'video' bir sınıf (SwiftData @Model) olduğu için,
            // bu atama doğrudan ana 'LineupVideo' örneğini günceller.
            video.localVideoPath = localFileURL.path
            try context.save() // Değişikliği SwiftData'ya kaydet
            checkLocalVideoStatus() // Durumu güncelle
            print("Simulated download complete. Path: \(video.localVideoPath ?? "N/A")")
            
        } catch {
            downloadError = "Simulated download failed: \(error.localizedDescription)"
        }
        // ----- Simülasyon Sonu -----
        
        isDownloading = false
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
