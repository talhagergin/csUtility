// Views/Videos/LineupVideosListView.swift
import SwiftUI

struct LineupVideosListView: View {
    @StateObject var viewModel: LineupVideoViewModel
    @EnvironmentObject var accountViewModel: AccountViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Videolar yükleniyor...")
            } else if let error = viewModel.errorMessage {
                Text("Hata: \(error)")
                    .foregroundColor(.red)
            } else if viewModel.categorizedVideos.isEmpty { // Kategorize edilmiş video yoksa
                Text("Bu kategori için henüz video bulunmamaktadır.")
                    .foregroundColor(.secondary)
            } else {
                List {
                    ForEach(viewModel.sortedCategoryKeys, id: \.self) { categoryKey in
                        // O kategoriye ait videoları al
                        if let videosInCategory = viewModel.categorizedVideos[categoryKey] {
                            Section(header: Text(categoryKey).font(.title3).fontWeight(.medium)) { // Kategori başlığı
                                ForEach(videosInCategory) { video in
                                    NavigationLink(value: video) {
                                        VStack(alignment: .leading) {
                                            Text(video.title)
                                                .font(.headline)
                                            // İsterseniz YouTube linkini veya küçük resmi burada da gösterebilirsiniz.
                                            // Text("YouTube Linki")
                                            //     .font(.caption)
                                            //     .foregroundColor(.blue)
                                        }
                                        .padding(.vertical, 4) // Satırlar arası biraz boşluk
                                    }
                                }
                                .onDelete(perform: accountViewModel.isAdmin ? { indexSet in
                                    deleteVideo(inCategory: categoryKey, at: indexSet)
                                } : nil)
                            }
                        }
                    }
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
                            onUploadComplete: {
                                viewModel.fetchVideos()
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
        // .onAppear { // ViewModel init'te zaten çağrılıyor.
        //     viewModel.fetchVideos()
        // }
    }
    
    // Silme işlemi artık kategori bazlı olmalı
    private func deleteVideo(inCategory category: String, at offsets: IndexSet) {
        guard let videosInCategory = viewModel.categorizedVideos[category] else { return }
        offsets.forEach { index in
            let videoToDelete = videosInCategory[index]
            viewModel.deleteVideo(video: videoToDelete) // ViewModel'deki ana silme fonksiyonunu çağır
        }
        // ViewModel.fetchVideos() zaten deleteVideo içinde çağrılıyor, listeyi yenileyecektir.
    }
}
