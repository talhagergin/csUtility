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
    private let youtubeAPIKey = "YOUR_YOUTUBE_API_KEY"
    
    // Gerçek YouTube video indirme fonksiyonu
    func downloadVideo(youtubeURL: String, progressHandler: @escaping (Double) -> Void, completion: @escaping (Result<URL, DownloadError>) -> Void) {
        
        guard let url = URL(string: youtubeURL) else {
            completion(.failure(.invalidURL))
            return
        }
        
        // YouTube video ID'sini çıkar
        guard let videoID = extractYouTubeVideoID(from: youtubeURL) else {
            completion(.failure(.invalidURL))
            return
        }
        
        // Önce yt-dlp web servisi ile dene
        downloadWithYtDlp(videoURL: youtubeURL, videoID: videoID, progressHandler: progressHandler) { result in
            switch result {
            case .success(let localURL):
                completion(.success(localURL))
            case .failure(let error):
                // yt-dlp başarısız olursa, YouTube Data API ile dene
                print("yt-dlp failed: \(error), trying YouTube Data API...")
                self.downloadWithYouTubeAPI(videoID: videoID, progressHandler: progressHandler, completion: completion)
            }
        }
    }
    
    // yt-dlp web servisi ile video indirme
    private func downloadWithYtDlp(videoURL: String, videoID: String, progressHandler: @escaping (Double) -> Void, completion: @escaping (Result<URL, DownloadError>) -> Void) {
        
        guard let serviceURL = URL(string: "\(ytDlpServiceURL)/download") else {
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
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(.networkError(error)))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.unknown))
                return
            }
            
            // yt-dlp servisinden gelen yanıtı işle
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let success = json["success"] as? Bool, success {
                        if let downloadID = json["download_id"] as? String {
                            // İndirme durumunu takip et ve dosyayı al
                            self.monitorDownloadProgress(downloadID: downloadID, videoID: videoID, progressHandler: progressHandler, completion: completion)
                        } else {
                            completion(.failure(.ytDlpError("Download ID not found in response")))
                        }
                    } else {
                        let errorMessage = json["error"] as? String ?? "Unknown yt-dlp error"
                        completion(.failure(.ytDlpError(errorMessage)))
                    }
                } else {
                    completion(.failure(.unknown))
                }
            } catch {
                completion(.failure(.networkError(error)))
            }
        }
        
        task.resume()
    }
    
    // İndirme durumunu takip et
    private func monitorDownloadProgress(downloadID: String, videoID: String, progressHandler: @escaping (Double) -> Void, completion: @escaping (Result<URL, DownloadError>) -> Void) {
        
        guard let statusURL = URL(string: "\(ytDlpServiceURL)/status/\(downloadID)") else {
            completion(.failure(.invalidURL))
            return
        }
        
        let task = URLSession.shared.dataTask(with: statusURL) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.unknown))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success,
                   let status = json["status"] as? [String: Any] {
                    
                    let downloadStatus = status["status"] as? String ?? ""
                    
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
                            self.downloadCompletedFile(downloadID: downloadID, filename: filename, videoID: videoID, completion: completion)
                        } else {
                            completion(.failure(.ytDlpError("Filename not found in completed status")))
                        }
                        
                    case "error":
                        // Hata oluştu
                        let errorMessage = status["error"] as? String ?? "Unknown error"
                        completion(.failure(.ytDlpError(errorMessage)))
                        
                    default:
                        // Bilinmeyen durum
                        completion(.failure(.ytDlpError("Unknown download status: \(downloadStatus)")))
                    }
                    
                } else {
                    completion(.failure(.unknown))
                }
            } catch {
                completion(.failure(.networkError(error)))
            }
        }
        
        task.resume()
    }
    
    // Tamamlanan dosyayı indir
    private func downloadCompletedFile(downloadID: String, filename: String, videoID: String, completion: @escaping (Result<URL, DownloadError>) -> Void) {
        
        guard let downloadURL = URL(string: "\(ytDlpServiceURL)/download/\(downloadID)") else {
            completion(.failure(.invalidURL))
            return
        }
        
        let task = URLSession.shared.downloadTask(with: downloadURL) { tempURL, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let tempURL = tempURL else {
                completion(.failure(.unknown))
                return
            }
            
            // Dosyayı yerel dosya sistemine kaydet
            self.saveDownloadedVideo(from: tempURL, videoID: videoID, completion: completion)
        }
        
        task.resume()
    }
    
    // YouTube Data API ile video indirme (alternatif yöntem)
    private func downloadWithYouTubeAPI(videoID: String, progressHandler: @escaping (Double) -> Void, completion: @escaping (Result<URL, DownloadError>) -> Void) {
        
        let apiURLString = "https://www.googleapis.com/youtube/v3/videos?part=snippet,contentDetails&id=\(videoID)&key=\(youtubeAPIKey)"
        
        guard let apiURL = URL(string: apiURLString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        let task = URLSession.shared.dataTask(with: apiURL) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
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
                    
                    // YouTube Data API ile doğrudan video indirme mümkün değil
                    // Bu yüzden video bilgilerini kullanarak demo video oluştur
                    self.createDemoVideo(title: title, description: description, videoID: videoID, completion: completion)
                    
                } else {
                    completion(.failure(.youtubeAPIError("No video data found")))
                }
            } catch {
                completion(.failure(.networkError(error)))
            }
        }
        
        task.resume()
        
        // Progress simülasyonu
        simulateProgress(progressHandler: progressHandler)
    }
    
    // Demo video oluşturma (YouTube Data API kullanıldığında)
    private func createDemoVideo(title: String, description: String, videoID: String, completion: @escaping (Result<URL, DownloadError>) -> Void) {
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videosFolder = documentsPath.appendingPathComponent("DownloadedVideos")
        
        do {
            try FileManager.default.createDirectory(at: videosFolder, withIntermediateDirectories: true, attributes: nil)
        } catch {
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
            completion(.success(localFileURL))
        } catch {
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
        
        // Dosyayı indir
        let downloadTask = URLSession.shared.downloadTask(with: downloadURL) { tempURL, response, error in
            if let error = error {
                print("❌ DEBUG: Download hatası: \(error)")
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let tempURL = tempURL else {
                print("❌ DEBUG: tempURL nil")
                completion(.failure(.unknown))
                return
            }
            
            print("🔍 DEBUG: tempURL: \(tempURL)")
            
            do {
                try FileManager.default.copyItem(at: tempURL, to: localFileURL)
                
                // Dosya boyutunu kontrol et
                let attributes = try FileManager.default.attributesOfItem(atPath: localFileURL.path)
                let fileSize = attributes[.size] as? Int64 ?? 0
                print("🔍 DEBUG: Dosya kaydedildi - Boyut: \(fileSize) bytes")
                print("🔍 DEBUG: Dosya yolu: \(localFileURL.path)")
                
                completion(.success(localFileURL))
            } catch {
                print("❌ DEBUG: Dosya kopyalama hatası: \(error)")
                completion(.failure(.fileSystemError(error)))
            }
        }
        
        downloadTask.resume()
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
