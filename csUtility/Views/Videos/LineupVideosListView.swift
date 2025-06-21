// Views/Videos/LineupVideosListView.swift
import SwiftUI

struct LineupVideosListView: View {
    @StateObject var viewModel: LineupVideoViewModel
    @EnvironmentObject var accountViewModel: AccountViewModel
    @Environment(\.modelContext) private var modelContext
    
    @State private var showThumbnails: Bool = true // Kullanıcı tercihi için
    @State private var downloadingVideos: Set<UUID> = [] // İndirilen videoları takip etmek için

    var body: some View {
        VStack {
            // Thumbnail gösterme/gizleme toggle'ı
            HStack {
                Toggle("Lineup görsellerini göster", isOn: $showThumbnails)
                    .toggleStyle(SwitchToggleStyle())
                Spacer()
            }
            .padding([.horizontal, .top])
            
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
                                            HStack(alignment: .center, spacing: 12) {
                                                if showThumbnails, let url = video.youtubeThumbnailURL {
                                                    AsyncImage(url: url) { image in
                                                        image
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                            .frame(width: 120, height: 68)
                                                            .clipped()
                                                            .cornerRadius(8)
                                                    } placeholder: {
                                                        Rectangle()
                                                            .fill(Color.gray.opacity(0.2))
                                                            .frame(width: 120, height: 68)
                                                            .cornerRadius(8)
                                                            .overlay(
                                                                ProgressView()
                                                            )
                                                    }
                                                }
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(video.title)
                                                        .font(.headline)
                                                    HStack {
                                                        if video.localVideoPath != nil && !video.localVideoPath!.isEmpty {
                                                            Label("İndirildi", systemImage: "checkmark.circle.fill")
                                                                .font(.caption)
                                                                .foregroundColor(.green)
                                                        } else if downloadingVideos.contains(video.id) {
                                                            ProgressView()
                                                                .scaleEffect(0.7)
                                                            Text("İndiriliyor...")
                                                                .font(.caption)
                                                                .foregroundColor(.blue)
                                                        } else {
                                                            Button(action: {
                                                                downloadVideo(video)
                                                            }) {
                                                                Label("İndir", systemImage: "arrow.down.circle")
                                                                    .font(.caption)
                                                                    .foregroundColor(.blue)
                                                            }
                                                            .buttonStyle(PlainButtonStyle())
                                                        }
                                                        Spacer()
                                                    }
                                                }
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
    
    // Video indirme fonksiyonu
    private func downloadVideo(_ video: LineupVideo) {
        downloadingVideos.insert(video.id)
        
        Task {
            let playerViewModel = VideoPlayerViewModel(video: video)
            await playerViewModel.downloadVideo(context: modelContext)
            
            await MainActor.run {
                downloadingVideos.remove(video.id)
            }
        }
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
