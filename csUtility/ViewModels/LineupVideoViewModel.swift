import SwiftUI
import SwiftData

@MainActor
class LineupVideosViewModel: ObservableObject {
    @Published var videos: [LineupVideo] = []
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
        
        let mapName = selectedMap.rawValue
        let utilityRaw = selectedUtility.rawValue
        
        let predicate = #Predicate<LineupVideo> { video in
            video.mapName == mapName && video.utilityTypeRawValue == utilityRaw
        }
        let sortDescriptor = SortDescriptor(\LineupVideo.uploadedDate, order: .reverse)
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [sortDescriptor])

        do {
            videos = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to fetch videos: \(error.localizedDescription)"
            print(errorMessage!)
        }
        isLoading = false
    }
    
    func deleteVideo(video: LineupVideo) {
        modelContext.delete(video)
        // İndirilmiş dosyayı da silmek gerekebilir.
        if let localPath = video.localVideoPath, !localPath.isEmpty {
            // VideoDownloadService.deleteLocalFile(atPath: localPath)
        }
        fetchVideos() // Listeyi yenile
    }
}
