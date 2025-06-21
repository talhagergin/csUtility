import Foundation

enum FirebaseVideoServiceError: Error {
    case invalidURL
    case networkError(Error)
    case firebaseError(String)
    case noVideoFound
    case unknown
}

class FirebaseVideoService {
    // Firebase Functions URL'i - deployment sonrası güncellenecek
    private let baseURL = "https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net"
    
    // Video indirme fonksiyonu
    func downloadVideo(youtubeURL: String, progressHandler: @escaping (Double) -> Void, completion: @escaping (Result<URL, FirebaseVideoServiceError>) -> Void) {
        
        guard let url = URL(string: "\(baseURL)/downloadVideo") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = [
            "url": youtubeURL,
            "format": "best[height<=720]"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(.networkError(error)))
            return
        }
        
        // Progress simülasyonu (Firebase Functions'da gerçek progress tracking yok)
        progressHandler(0.1)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.unknown))
                return
            }
            
            // Progress güncelle
            progressHandler(0.5)
            
            // Video dosyasını kaydet
            self.saveDownloadedVideo(from: data, youtubeURL: youtubeURL, completion: completion)
        }
        
        task.resume()
    }
    
    // Video bilgilerini alma fonksiyonu
    func getVideoInfo(youtubeURL: String) async throws -> [String: Any] {
        guard let url = URL(string: "\(baseURL)/getVideoInfo?url=\(youtubeURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            throw FirebaseVideoServiceError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw FirebaseVideoServiceError.networkError(NSError(domain: "HTTP", code: 500))
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let success = json?["success"] as? Bool, success,
              let data = json?["data"] as? [String: Any] else {
            throw FirebaseVideoServiceError.firebaseError("Video bilgileri alınamadı")
        }
        
        return data
    }
    
    // Sağlık kontrolü
    func checkHealth() async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/health") else {
            throw FirebaseVideoServiceError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return false
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["success"] as? Bool ?? false
    }
    
    // İndirilen videoyu kaydet
    private func saveDownloadedVideo(from data: Data, youtubeURL: String, completion: @escaping (Result<URL, FirebaseVideoServiceError>) -> Void) {
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videosFolder = documentsPath.appendingPathComponent("DownloadedVideos")
        
        do {
            try FileManager.default.createDirectory(at: videosFolder, withIntermediateDirectories: true, attributes: nil)
        } catch {
            completion(.failure(.networkError(error)))
            return
        }
        
        // Video ID'sini URL'den çıkar
        guard let videoID = extractVideoID(from: youtubeURL) else {
            completion(.failure(.noVideoFound))
            return
        }
        
        let fileName = "\(videoID).mp4"
        let localFileURL = videosFolder.appendingPathComponent(fileName)
        
        // Eğer dosya zaten varsa sil
        if FileManager.default.fileExists(atPath: localFileURL.path) {
            try? FileManager.default.removeItem(at: localFileURL)
        }
        
        // Video dosyasını kaydet
        do {
            try data.write(to: localFileURL)
            
            // Progress tamamlandı
            completion(.success(localFileURL))
        } catch {
            completion(.failure(.networkError(error)))
        }
    }
    
    // YouTube video ID'sini URL'den çıkar
    private func extractVideoID(from urlString: String) -> String? {
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
} 