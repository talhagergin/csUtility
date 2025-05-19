// LineupVideosListView.swift

import SwiftUI
import SwiftData // modelContext için eklendi (AdminUploadVideoView'a geçerken)

struct LineupVideosListView: View {
    // Düzeltilmiş ViewModel tipi: LineupVideosViewModel
    @StateObject var viewModel: LineupVideosViewModel
    @EnvironmentObject var accountViewModel: AccountViewModel // Admin kontrolü için
    @Environment(\.modelContext) private var modelContext // AdminUploadVideoView'a geçmek için eklendi

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Videolar yükleniyor...")
            } else if let error = viewModel.errorMessage {
                Text("Hata: \(error)")
                    .foregroundColor(.red)
            } else if viewModel.videos.isEmpty {
                Text("Bu kategori için henüz video bulunmamaktadır.")
                    .foregroundColor(.secondary)
            } else {
                List {
                    ForEach(viewModel.videos) { video in
                        NavigationLink(value: video) {
                            VStack(alignment: .leading) {
                                Text(video.title)
                                    .font(.headline)
                                Text("YouTube Linki") // Veya küçük resim
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .onDelete(perform: accountViewModel.isAdmin ? deleteVideo : nil)
                }
            }
        }
        .navigationTitle("\(viewModel.selectedMap.displayName) - \(viewModel.selectedUtility.rawValue)")
        .toolbar {
            if accountViewModel.isAdmin {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        AdminUploadVideoView(
                            map: viewModel.selectedMap,
                            utilityType: viewModel.selectedUtility,
                           // modelContext: modelContext, // modelContext'i AdminUploadVideoView'a geçirin
                            onUploadComplete: {
                                viewModel.fetchVideos() // Video eklendikten sonra listeyi yenile
                            }
                        )
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
        .navigationDestination(for: LineupVideo.self) { video in
            VideoPlayerView(video: video)
        }
        .onAppear {
            // viewModel.fetchVideos() // ViewModel init'te zaten çağrılıyor.
        }
    }
    
    private func deleteVideo(at offsets: IndexSet) {
        offsets.forEach { index in
            let videoToDelete = viewModel.videos[index]
            viewModel.deleteVideo(video: videoToDelete)
        }
    }
}
