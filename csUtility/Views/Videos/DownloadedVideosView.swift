import SwiftUI
import SwiftData

struct DownloadedVideosView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var settingsViewModel = SettingsViewModel()
    @State private var downloadedVideos: [LineupVideo] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("İndirilen videolar yükleniyor...")
                } else if downloadedVideos.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Henüz İndirilmiş Video Yok")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                        
                        Text("Video indirme özelliğini ayarlardan aktif edip videolar indirebilirsiniz.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Debug bilgileri
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Debug Bilgileri:")
                                .font(.caption)
                                .fontWeight(.bold)
                            
                            Text("Toplam Video Sayısı: \(getTotalVideoCount())")
                                .font(.caption)
                            
                            Text("İndirilmiş Video Sayısı: \(getDownloadedVideoCount())")
                                .font(.caption)
                            
                            Text("Video İndirme Aktif: \(settingsViewModel.isVideoDownloadEnabled ? "Evet" : "Hayır")")
                                .font(.caption)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        
                        if !settingsViewModel.isVideoDownloadEnabled {
                            Button("Ayarları Aç") {
                                // Ayarlar sayfasını açmak için
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        
                        Button("Yenile") {
                            loadDownloadedVideos()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(downloadedVideos) { video in
                            NavigationLink(value: video) {
                                DownloadedVideoRowView(video: video)
                            }
                        }
                        .onDelete(perform: deleteVideos)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("İndirilen Videolar")
            .toolbar {
                if !downloadedVideos.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Tümünü Sil") {
                            deleteAllVideos()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationDestination(for: LineupVideo.self) { video in
                VideoPlayerView(video: video)
            }
        }
        .onAppear {
            loadDownloadedVideos()
        }
        .refreshable {
            loadDownloadedVideos()
        }
    }
    
    private func loadDownloadedVideos() {
        print("🔍 DEBUG: loadDownloadedVideos çağrıldı")
        isLoading = true
        
        let descriptor = FetchDescriptor<LineupVideo>(
            predicate: #Predicate<LineupVideo> { video in
                video.localVideoPath != nil
            },
            sortBy: [SortDescriptor(\.uploadedDate, order: .reverse)]
        )
        
        do {
            downloadedVideos = try modelContext.fetch(descriptor)
            print("🔍 DEBUG: İndirilmiş video sayısı: \(downloadedVideos.count)")
            
            // Boş olmayan localVideoPath'leri filtrele ve geçersiz dosyaları temizle
            downloadedVideos = downloadedVideos.filter { video in
                if let path = video.localVideoPath, !path.isEmpty {
                    // Dosyanın gerçekten var olup olmadığını kontrol et
                    let fileExists = FileManager.default.fileExists(atPath: path)
                    print("🔍 DEBUG: Video: \(video.title)")
                    print("🔍 DEBUG: - localVideoPath: \(path)")
                    print("🔍 DEBUG: - Dosya var mı: \(fileExists)")
                    
                    if fileExists {
                        // Dosya boyutunu kontrol et
                        do {
                            let attributes = try FileManager.default.attributesOfItem(atPath: path)
                            let fileSize = attributes[.size] as? Int64 ?? 0
                            print("🔍 DEBUG: - Dosya boyutu: \(fileSize) bytes")
                            
                            // Minimum 1KB boyut kontrolü
                            if fileSize < 1024 {
                                print("❌ DEBUG: Dosya çok küçük, temizleniyor")
                                try? FileManager.default.removeItem(atPath: path)
                                video.localVideoPath = nil
                                return false
                            }
                            
                            return true
                        } catch {
                            print("❌ DEBUG: Dosya özellikleri alınamadı, temizleniyor: \(error)")
                            try? FileManager.default.removeItem(atPath: path)
                            video.localVideoPath = nil
                            return false
                        }
                    } else {
                        print("❌ DEBUG: Dosya bulunamadı, veritabanından temizleniyor")
                        video.localVideoPath = nil
                        return false
                    }
                }
                return false
            }
            
            // Değişiklikleri kaydet
            try? modelContext.save()
            
            print("🔍 DEBUG: Filtrelenmiş video sayısı: \(downloadedVideos.count)")
            
        } catch {
            print("❌ DEBUG: Error fetching downloaded videos: \(error)")
        }
        
        isLoading = false
    }
    
    private func getTotalVideoCount() -> Int {
        let descriptor = FetchDescriptor<LineupVideo>()
        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            return 0
        }
    }
    
    private func getDownloadedVideoCount() -> Int {
        let descriptor = FetchDescriptor<LineupVideo>(
            predicate: #Predicate<LineupVideo> { video in
                video.localVideoPath != nil
            }
        )
        do {
            let allVideos = try modelContext.fetch(descriptor)
            return allVideos.filter { video in
                if let path = video.localVideoPath, !path.isEmpty {
                    return FileManager.default.fileExists(atPath: path)
                }
                return false
            }.count
        } catch {
            return 0
        }
    }
    
    private func deleteVideos(offsets: IndexSet) {
        for index in offsets {
            let video = downloadedVideos[index]
            deleteVideo(video)
        }
        loadDownloadedVideos()
    }
    
    private func deleteVideo(_ video: LineupVideo) {
        // Önce dosyayı sil
        if let path = video.localVideoPath, !path.isEmpty {
            do {
                try FileManager.default.removeItem(atPath: path)
                print("Deleted video file: \(path)")
            } catch {
                print("Error deleting video file: \(error)")
            }
        }
        
        // Sonra veritabanından kaldır
        video.localVideoPath = nil
        try? modelContext.save()
    }
    
    private func deleteAllVideos() {
        for video in downloadedVideos {
            deleteVideo(video)
        }
        loadDownloadedVideos()
    }
}

struct DownloadedVideoRowView: View {
    let video: LineupVideo
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Video thumbnail
            if let url = video.youtubeThumbnailURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 45)
                        .clipped()
                        .cornerRadius(6)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 45)
                        .cornerRadius(6)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.7)
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack {
                    Text(video.mapName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(video.utilityTypeRawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let category = video.category {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Label("İndirildi", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Text(video.uploadedDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DownloadedVideosView()
        .modelContainer(AppModelContainer.shared)
} 