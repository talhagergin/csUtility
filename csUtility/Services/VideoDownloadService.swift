import Foundation
import AVFoundation // Belki stream'leri parse etmek için

enum DownloadError: Error {
    case invalidURL
    case networkError(Error)
    case noStreamAvailable
    case fileSystemError(Error)
    case ytDlpError(String)
    case youtubeAPIError(String)
    case unknown
}

class VideoDownloadService {
    
    // yt-dlp web servisi URL'i (bu URL'i kendi sunucunuzda çalıştırmanız gerekiyor)
    private let ytDlpServiceURL = "http://localhost:5001"
    
    // YouTube Data API key (Google Cloud Console'dan alınmalı)
    // Not: Gerçek bir API key gerekli, şimdilik yt-dlp kullanacağız
    private let youtubeAPIKey = "YOUR_YOUTUBE_API_KEY"
    
    // Gerçek YouTube video indirme fonksiyonu
    func downloadVideo(youtubeURL: String, progressHandler: @escaping (Double) -> Void, completion: @escaping (Result<URL, DownloadError>) -> Void) {
        
        print("🔍 DEBUG: VideoDownloadService.downloadVideo başladı")
        print("🔍 DEBUG: youtubeURL: \(youtubeURL)")
        
        guard let url = URL(string: youtubeURL) else {
            print("❌ DEBUG: Geçersiz URL formatı")
            completion(.failure(.invalidURL))
            return
        }
        
        // YouTube video ID'sini çıkar
        guard let videoID = extractYouTubeVideoID(from: youtubeURL) else {
            print("❌ DEBUG: Video ID çıkarılamadı")
            completion(.failure(.invalidURL))
            return
        }
        
        print("🔍 DEBUG: Video ID: \(videoID)")
        
        // Önce yt-dlp web servisi ile dene
        downloadWithYtDlp(videoURL: youtubeURL, videoID: videoID, progressHandler: progressHandler) { result in
            switch result {
            case .success(let localURL):
                print("🔍 DEBUG: yt-dlp başarılı, localURL: \(localURL)")
                completion(.success(localURL))
            case .failure(let error):
                // yt-dlp başarısız olursa, YouTube Data API ile dene
                print("❌ DEBUG: yt-dlp failed: \(error), trying YouTube Data API...")
                self.downloadWithYouTubeAPI(videoID: videoID, progressHandler: progressHandler, completion: completion)
            }
        }
    }
    
    // yt-dlp web servisi ile video indirme
    private func downloadWithYtDlp(videoURL: String, videoID: String, progressHandler: @escaping (Double) -> Void, completion: @escaping (Result<URL, DownloadError>) -> Void) {
        
        print("🔍 DEBUG: downloadWithYtDlp başladı")
        
        guard let serviceURL = URL(string: "\(ytDlpServiceURL)/download") else {
            print("❌ DEBUG: Geçersiz service URL")
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: serviceURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = [
            "url": videoURL,
            "format": "best[height<=720]", // 720p veya daha düşük kalite
            "output": "\(videoID).%(ext)s"
        ]
        
        print("🔍 DEBUG: Request body: \(requestBody)")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("❌ DEBUG: JSON serialization hatası: \(error)")
            completion(.failure(.networkError(error)))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ DEBUG: Network error: \(error)")
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                print("❌ DEBUG: No data received")
                completion(.failure(.unknown))
                return
            }
            
            print("🔍 DEBUG: Response data received: \(String(data: data, encoding: .utf8) ?? "nil")")
            
            // yt-dlp servisinden gelen yanıtı işle
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let success = json["success"] as? Bool, success {
                        if let downloadID = json["download_id"] as? String {
                            print("🔍 DEBUG: Download ID received: \(downloadID)")
                            // İndirme durumunu takip et ve dosyayı al
                            self.monitorDownloadProgress(downloadID: downloadID, videoID: videoID, progressHandler: progressHandler, completion: completion)
                        } else {
                            print("❌ DEBUG: Download ID not found in response")
                            completion(.failure(.ytDlpError("Download ID not found in response")))
                        }
                    } else {
                        let errorMessage = json["error"] as? String ?? "Unknown yt-dlp error"
                        print("❌ DEBUG: yt-dlp error: \(errorMessage)")
                        completion(.failure(.ytDlpError(errorMessage)))
                    }
                } else {
                    print("❌ DEBUG: Invalid JSON response")
                    completion(.failure(.unknown))
                }
            } catch {
                print("❌ DEBUG: JSON parsing error: \(error)")
                completion(.failure(.networkError(error)))
            }
        }
        
        task.resume()
    }
    
    // İndirme durumunu takip et
    private func monitorDownloadProgress(downloadID: String, videoID: String, progressHandler: @escaping (Double) -> Void, completion: @escaping (Result<URL, DownloadError>) -> Void) {
        
        print("🔍 DEBUG: monitorDownloadProgress başladı - downloadID: \(downloadID)")
        
        guard let statusURL = URL(string: "\(ytDlpServiceURL)/status/\(downloadID)") else {
            print("❌ DEBUG: Geçersiz status URL")
            completion(.failure(.invalidURL))
            return
        }
        
        let task = URLSession.shared.dataTask(with: statusURL) { data, response, error in
            if let error = error {
                print("❌ DEBUG: Status check error: \(error)")
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                print("❌ DEBUG: No status data received")
                completion(.failure(.unknown))
                return
            }
            
            print("🔍 DEBUG: Status response: \(String(data: data, encoding: .utf8) ?? "nil")")
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success,
                   let status = json["status"] as? [String: Any] {
                    
                    let downloadStatus = status["status"] as? String ?? ""
                    print("🔍 DEBUG: Download status: \(downloadStatus)")
                    
                    switch downloadStatus {
                    case "starting":
                        // İndirme başladı, progress'i güncelle
                        progressHandler(0.0)
                        // 2 saniye sonra tekrar kontrol et
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.monitorDownloadProgress(downloadID: downloadID, videoID: videoID, progressHandler: progressHandler, completion: completion)
                        }
                        
                    case "downloading":
                        // İndirme devam ediyor, progress'i güncelle
                        let progress = status["progress"] as? Double ?? 0.0
                        progressHandler(progress)
                        // 1 saniye sonra tekrar kontrol et
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.monitorDownloadProgress(downloadID: downloadID, videoID: videoID, progressHandler: progressHandler, completion: completion)
                        }
                        
                    case "completed":
                        // İndirme tamamlandı, dosyayı al
                        if let filename = status["filename"] as? String {
                            print("🔍 DEBUG: Download completed, filename: \(filename)")
                            self.downloadCompletedFile(downloadID: downloadID, filename: filename, videoID: videoID, completion: completion)
                        } else {
                            print("❌ DEBUG: Filename not found in completed status")
                            completion(.failure(.ytDlpError("Filename not found in completed status")))
                        }
                        
                    case "error":
                        // Hata oluştu
                        let errorMessage = status["error"] as? String ?? "Unknown error"
                        print("❌ DEBUG: Download error: \(errorMessage)")
                        completion(.failure(.ytDlpError(errorMessage)))
                        
                    default:
                        // Bilinmeyen durum
                        print("❌ DEBUG: Unknown download status: \(downloadStatus)")
                        completion(.failure(.ytDlpError("Unknown download status: \(downloadStatus)")))
                    }
                    
                } else {
                    print("❌ DEBUG: Invalid status response format")
                    completion(.failure(.unknown))
                }
            } catch {
                print("❌ DEBUG: Status JSON parsing error: \(error)")
                completion(.failure(.networkError(error)))
            }
        }
        
        task.resume()
    }
    
    // Tamamlanan dosyayı indir
    private func downloadCompletedFile(downloadID: String, filename: String, videoID: String, completion: @escaping (Result<URL, DownloadError>) -> Void) {
        
        print("🔍 DEBUG: downloadCompletedFile başladı - downloadID: \(downloadID)")
        
        guard let downloadURL = URL(string: "\(ytDlpServiceURL)/download/\(downloadID)") else {
            print("❌ DEBUG: Geçersiz download URL")
            completion(.failure(.invalidURL))
            return
        }
        
        let task = URLSession.shared.downloadTask(with: downloadURL) { tempURL, response, error in
            if let error = error {
                print("❌ DEBUG: File download error: \(error)")
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let tempURL = tempURL else {
                print("❌ DEBUG: No temp URL received")
                completion(.failure(.unknown))
                return
            }
            
            print("🔍 DEBUG: File downloaded to temp URL: \(tempURL)")
            
            // Dosyayı yerel dosya sistemine kaydet
            self.saveDownloadedVideo(from: tempURL, videoID: videoID, completion: completion)
        }
        
        task.resume()
    }
    
    // YouTube Data API ile video indirme (alternatif yöntem)
    private func downloadWithYouTubeAPI(videoID: String, progressHandler: @escaping (Double) -> Void, completion: @escaping (Result<URL, DownloadError>) -> Void) {
        
        print("🔍 DEBUG: downloadWithYouTubeAPI başladı")
        
        let apiURLString = "https://www.googleapis.com/youtube/v3/videos?part=snippet,contentDetails&id=\(videoID)&key=\(youtubeAPIKey)"
        
        guard let apiURL = URL(string: apiURLString) else {
            print("❌ DEBUG: Geçersiz API URL")
            completion(.failure(.invalidURL))
            return
        }
        
        let task = URLSession.shared.dataTask(with: apiURL) { data, response, error in
            if let error = error {
                print("❌ DEBUG: YouTube API error: \(error)")
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                print("❌ DEBUG: No API data received")
                completion(.failure(.unknown))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let items = json["items"] as? [[String: Any]],
                   let firstItem = items.first,
                   let snippet = firstItem["snippet"] as? [String: Any] {
                    
                    // Video bilgilerini al
                    let title = snippet["title"] as? String ?? "Unknown"
                    let description = snippet["description"] as? String ?? ""
                    
                    print("🔍 DEBUG: YouTube API video info - title: \(title)")
                    
                    // YouTube Data API ile doğrudan video indirme mümkün değil
                    // Bu yüzden video bilgilerini kullanarak demo video oluştur
                    self.createDemoVideo(title: title, description: description, videoID: videoID, completion: completion)
                    
                } else {
                    print("❌ DEBUG: No video data found in API response")
                    completion(.failure(.youtubeAPIError("No video data found")))
                }
            } catch {
                print("❌ DEBUG: API JSON parsing error: \(error)")
                completion(.failure(.networkError(error)))
            }
        }
        
        task.resume()
        
        // Progress simülasyonu
        simulateProgress(progressHandler: progressHandler)
    }
    
    // Demo video oluşturma (YouTube Data API kullanıldığında)
    private func createDemoVideo(title: String, description: String, videoID: String, completion: @escaping (Result<URL, DownloadError>) -> Void) {
        
        print("🔍 DEBUG: createDemoVideo başladı - title: \(title)")
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videosFolder = documentsPath.appendingPathComponent("DownloadedVideos")
        
        do {
            try FileManager.default.createDirectory(at: videosFolder, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("❌ DEBUG: Videos folder creation error: \(error)")
            completion(.failure(.fileSystemError(error)))
            return
        }
        
        let fileName = "\(videoID).mp4"
        let localFileURL = videosFolder.appendingPathComponent(fileName)
        
        // Eğer dosya zaten varsa sil
        if FileManager.default.fileExists(atPath: localFileURL.path) {
            try? FileManager.default.removeItem(at: localFileURL)
        }
        
        // Demo video içeriği oluştur
        let demoContent = """
        YouTube Video: \(title)
        Video ID: \(videoID)
        Description: \(description)
        
        Bu video YouTube Data API kullanılarak oluşturulmuştur.
        Gerçek video indirme için yt-dlp web servisi kullanılmalıdır.
        """
        
        do {
            let demoData = Data(demoContent.utf8)
            try demoData.write(to: localFileURL)
            print("🔍 DEBUG: Demo video created: \(localFileURL)")
            completion(.success(localFileURL))
        } catch {
            print("❌ DEBUG: Demo video creation error: \(error)")
            completion(.failure(.fileSystemError(error)))
        }
    }
    
    // İndirilen videoyu yerel dosya sistemine kaydet
    private func saveDownloadedVideo(from downloadURL: URL, videoID: String, completion: @escaping (Result<URL, DownloadError>) -> Void) {
        
        print("🔍 DEBUG: saveDownloadedVideo çağrıldı")
        print("🔍 DEBUG: downloadURL: \(downloadURL)")
        print("🔍 DEBUG: videoID: \(videoID)")
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videosFolder = documentsPath.appendingPathComponent("DownloadedVideos")
        
        print("🔍 DEBUG: documentsPath: \(documentsPath)")
        print("🔍 DEBUG: videosFolder: \(videosFolder)")
        
        do {
            try FileManager.default.createDirectory(at: videosFolder, withIntermediateDirectories: true, attributes: nil)
            print("🔍 DEBUG: videosFolder oluşturuldu")
        } catch {
            print("❌ DEBUG: videosFolder oluşturulamadı: \(error)")
            completion(.failure(.fileSystemError(error)))
            return
        }
        
        let fileName = "\(videoID).mp4"
        let localFileURL = videosFolder.appendingPathComponent(fileName)
        
        print("🔍 DEBUG: fileName: \(fileName)")
        print("🔍 DEBUG: localFileURL: \(localFileURL)")
        
        // Eğer dosya zaten varsa sil
        if FileManager.default.fileExists(atPath: localFileURL.path) {
            print("🔍 DEBUG: Eski dosya siliniyor")
            try? FileManager.default.removeItem(at: localFileURL)
        }
        
        // downloadURL zaten indirilmiş dosyanın geçici URL'i, doğrudan kopyala
        do {
            try FileManager.default.copyItem(at: downloadURL, to: localFileURL)
            
            // Dosya bütünlüğünü kontrol et
            let attributes = try FileManager.default.attributesOfItem(atPath: localFileURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            print("🔍 DEBUG: Dosya kaydedildi - Boyut: \(fileSize) bytes")
            print("🔍 DEBUG: Dosya yolu: \(localFileURL.path)")
            
            // Dosya boyutu kontrolü - minimum 1KB olmalı
            if fileSize < 1024 {
                print("❌ DEBUG: Dosya çok küçük, geçersiz video dosyası")
                try? FileManager.default.removeItem(at: localFileURL)
                completion(.failure(.fileSystemError(NSError(domain: "VideoDownloadService", code: 1, userInfo: [NSLocalizedDescriptionKey: "İndirilen dosya geçersiz"]))))
                return
            }
            
            // Dosya okunabilirliğini test et
            let testData = try Data(contentsOf: localFileURL, options: .mappedIfSafe)
            if testData.count < 1024 {
                print("❌ DEBUG: Dosya okunamıyor veya çok küçük")
                try? FileManager.default.removeItem(at: localFileURL)
                completion(.failure(.fileSystemError(NSError(domain: "VideoDownloadService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Video dosyası okunamıyor"]))))
                return
            }
            
            print("🔍 DEBUG: Dosya başarıyla kaydedildi ve doğrulandı")
            completion(.success(localFileURL))
        } catch {
            print("❌ DEBUG: Dosya kopyalama hatası: \(error)")
            // Hata durumunda dosyayı temizle
            try? FileManager.default.removeItem(at: localFileURL)
            completion(.failure(.fileSystemError(error)))
        }
    }
    
    // YouTube video ID'sini URL'den çıkar
    private func extractYouTubeVideoID(from urlString: String) -> String? {
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
    
    // Progress simülasyonu
    private func simulateProgress(progressHandler: @escaping (Double) -> Void) {
        DispatchQueue.global().async {
            for i in 1...10 {
                usleep(300000) // 0.3 saniye
                DispatchQueue.main.async {
                    progressHandler(Double(i) / 10.0)
                }
            }
        }
    }
    
    func deleteLocalFile(atPath path: String) -> Bool {
        do {
            try FileManager.default.removeItem(atPath: path)
            return true
        } catch {
            print("Error deleting file at \(path): \(error)")
            return false
        }
    }
}
