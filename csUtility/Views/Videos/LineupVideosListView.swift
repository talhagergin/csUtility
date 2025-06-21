// Views/Videos/LineupVideosListView.swift
import SwiftUI

struct LineupVideosListView: View {
    @StateObject var viewModel: LineupVideoViewModel
    @EnvironmentObject var accountViewModel: AccountViewModel
    @Environment(\.modelContext) private var modelContext
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    @State private var downloadingVideos: Set<UUID> = [] // İndirilen videoları takip etmek için

    var body: some View {
        VStack {
            // Thumbnail gösterme/gizleme toggle'ı - artık ayarlardan alınıyor
            HStack {
                Toggle("Lineup görsellerini göster", isOn: $settingsViewModel.showThumbnails)
                    .toggleStyle(SwitchToggleStyle())
                Spacer()
            }
            .padding([.horizontal, .top])
            
            Group {
                if viewModel.isLoading {
                    ProgressView("Videolar yükleniyor...")
                } else if viewModel.categorizedVideos.isEmpty {
                    VStack {
                        Image(systemName: "video.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Bu kategoride henüz video bulunmuyor")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Admin hesabı ile yeni video ekleyebilirsiniz")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(viewModel.sortedCategoryKeys, id: \.self) { category in
                            if let videosInCategory = viewModel.categorizedVideos[category] {
                                Section(header: Text(category)) {
                                    ForEach(videosInCategory) { video in
                                        NavigationLink(value: video) {
                                            HStack(alignment: .center, spacing: 12) {
                                                if settingsViewModel.showThumbnails, let url = video.youtubeThumbnailURL {
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
                                                        } else if settingsViewModel.isVideoDownloadEnabled {
                                                            Button(action: {
                                                                downloadVideo(video)
                                                            }) {
                                                                Label("İndir", systemImage: "arrow.down.circle")
                                                                    .font(.caption)
                                                                    .foregroundColor(.blue)
                                                            }
                                                            .buttonStyle(PlainButtonStyle())
                                                        } else {
                                                            Text("İndirme Devre Dışı")
                                                                .font(.caption)
                                                                .foregroundColor(.secondary)
                                                        }
                                                        
                                                        Spacer()
                                                        
                                                        if accountViewModel.isAdmin {
                                                            Button(action: {
                                                                // Admin silme işlemi
                                                                viewModel.deleteVideo(video: video)
                                                            }) {
                                                                Image(systemName: "trash")
                                                                    .foregroundColor(.red)
                                                                    .font(.caption)
                                                            }
                                                            .buttonStyle(PlainButtonStyle())
                                                        }
                                                    }
                                                }
                                                
                                                Spacer()
                                            }
                                            .padding(.vertical, 4)
                                        }
                                    }
                                    .onDelete { offsets in
                                        deleteVideo(inCategory: category, at: offsets)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
        .navigationTitle("\(viewModel.selectedMap.displayName) - \(viewModel.selectedUtility.rawValue)")
        .toolbar {
            if accountViewModel.isAdmin {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AdminUploadVideoView(
                        map: viewModel.selectedMap,
                        utilityType: viewModel.selectedUtility
                    ) {
                        viewModel.fetchVideos()
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    private func downloadVideo(_ video: LineupVideo) {
        guard settingsViewModel.isVideoDownloadEnabled else { return }
        
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

