// ViewModels/LineupVideosViewModel.swift
import SwiftUI
import SwiftData

@MainActor
class LineupVideoViewModel: ObservableObject {
    // Videoları kategoriye göre gruplandırmak için bir dictionary kullanacağız.
    // Key: Kategori adı (String), Value: O kategoriye ait videolar ([LineupVideo])
    @Published var categorizedVideos: [String: [LineupVideo]] = [:]
    @Published var sortedCategoryKeys: [String] = [] // Kategori başlıklarını sıralı tutmak için
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var modelContext: ModelContext
    let selectedMap: CSMap
    let selectedUtility: UtilityType

    init(modelContext: ModelContext, map: CSMap, utility: UtilityType) {
        self.modelContext = modelContext
        self.selectedMap = map
        self.selectedUtility = utility
        fetchVideos()
    }

    func fetchVideos() {
        isLoading = true
        errorMessage = nil
        categorizedVideos = [:] // Her fetch öncesi temizle
        sortedCategoryKeys = []
        
        let mapName = selectedMap.rawValue
        let utilityRaw = selectedUtility.rawValue
        
        let predicate = #Predicate<LineupVideo> { video in
            video.mapName == mapName && video.utilityTypeRawValue == utilityRaw
        }
        // Videoları önce kategoriye, sonra yükleme tarihine göre sıralayabiliriz
        let sortDescriptors = [
            SortDescriptor(\LineupVideo.category), // Önce kategoriye göre (A-Z)
            SortDescriptor(\LineupVideo.uploadedDate, order: .reverse) // Sonra tarihe göre (en yeni)
        ]
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: sortDescriptors)

        do {
            let fetchedVideos = try modelContext.fetch(descriptor)
            
            // Videoları kategorilere göre grupla
            // Dictionary(grouping:by:) Swift 5 ile geldi, çok kullanışlı.
            categorizedVideos = Dictionary(grouping: fetchedVideos) { video -> String in
                // Eğer kategori yoksa veya boşsa "Genel" kategorisine ata
                return video.category?.isEmpty == false ? video.category! : LineupCategory.general.rawValue
            }
            
            // Kategori anahtarlarını (başlıklarını) alıp sırala
            // Özel bir sıralama isteniyorsa (örn: A Site, B Site, Mid...) burada yapılabilir.
            // Şimdilik alfabetik sıralıyoruz.
            // LineupCategory enum'ındaki sıraya göre de sıralayabiliriz.
            let categoryOrder = LineupCategory.allCases.map { $0.rawValue }
            
            sortedCategoryKeys = categorizedVideos.keys.sorted { key1, key2 in
                guard let index1 = categoryOrder.firstIndex(of: key1),
                      let index2 = categoryOrder.firstIndex(of: key2) else {
                    // Eğer bir kategori LineupCategory enum'ında yoksa, alfabetik olarak sona at.
                    if categoryOrder.contains(key1) { return true } // key1 enum'da var, key2 yok -> key1 önce
                    if categoryOrder.contains(key2) { return false } // key2 enum'da var, key1 yok -> key2 önce
                    return key1 < key2 // ikisi de enum'da yoksa alfabetik
                }
                return index1 < index2
            }
            // Eğer "Genel" kategorisi varsa ve sonda olmasını istiyorsak:
            if let generalIndex = sortedCategoryKeys.firstIndex(of: LineupCategory.general.rawValue) {
                let general = sortedCategoryKeys.remove(at: generalIndex)
                sortedCategoryKeys.append(general)
            }


        } catch {
            errorMessage = "Failed to fetch videos: \(error.localizedDescription)"
            print(errorMessage!)
        }
        isLoading = false
    }
    
    func deleteVideo(video: LineupVideo) { // Bu fonksiyonun da güncellenmesi gerekebilir.
        modelContext.delete(video)
        // İndirilmiş dosyayı da silmek gerekebilir.
        if let localPath = video.localVideoPath, !localPath.isEmpty {
            // VideoDownloadService.deleteLocalFile(atPath: localPath)
        }
        fetchVideos() // Listeyi ve kategorileri yenile
    }
}
