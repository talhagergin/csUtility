// VideoPlayerView.swift

import SwiftUI
import WebKit // YouTubeWebView için
import SwiftData // modelContext için
import AVKit

// ASIL VideoPlayerView STRUCT'I BU
struct VideoPlayerView: View {
    let video: LineupVideo // Artık @ObservedObject değil

    @StateObject private var playerViewModel: VideoPlayerViewModel
    @Environment(\.modelContext) private var modelContext
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var localVideoError: String?

    init(video: LineupVideo) {
        self.video = video
        _playerViewModel = StateObject(wrappedValue: VideoPlayerViewModel(video: video))
    }
    
    var body: some View {
        VStack {
            // Video oynatma alanı
            if let localPath = video.localVideoPath, !localPath.isEmpty {
                // Yerel video dosyasının varlığını kontrol et
                if FileManager.default.fileExists(atPath: localPath) {
                    let fileURL = URL(fileURLWithPath: localPath)
                    AVPlayerControllerView(videoURL: fileURL, onError: { error in
                        localVideoError = error
                    })
                    .frame(minHeight: 200, idealHeight: 300)
                    .cornerRadius(8)
                } else {
                    // Dosya bulunamadı - veritabanını temizle
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text("Video Dosyası Bulunamadı")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text("Video dosyası silinmiş veya taşınmış olabilir.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Veritabanını Temizle") {
                            video.localVideoPath = nil
                            try? modelContext.save()
                            localVideoError = nil
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.blue)
                    }
                    .padding()
                    .frame(minHeight: 200, idealHeight: 300)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            } else if let videoID = playerViewModel.extractYouTubeVideoID(from: video.youtubeURL) {
                // İnternet bağlantısı kontrolü
                if networkMonitor.isConnected {
                    YouTubeWebView(videoID: videoID)
                        .frame(minHeight: 200, idealHeight: 300)
                } else {
                    // İnternet bağlantısı yok
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text("İnternet Bağlantısı Gerekli")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text("Bu video oynatmak için internet bağlantısı gereklidir.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        if settingsViewModel.isVideoDownloadEnabled {
                            Button("Videoyu İndir") {
                                Task {
                                    await playerViewModel.downloadVideo(context: modelContext)
                                }
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .frame(minHeight: 200, idealHeight: 300)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            } else {
                Text("Geçersiz YouTube URL'si")
                    .foregroundColor(.red)
            }

            // Yerel video oynatma hatası
            if let error = localVideoError {
                Text("Video Oynatma Hatası: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            Text(video.title)
                .font(.title2)
                .padding()

            // Video indirme/mevcut durumu
            if video.localVideoPath == nil || video.localVideoPath!.isEmpty {
                if playerViewModel.isDownloading {
                    ProgressView("İndiriliyor: \(Int(playerViewModel.downloadProgress * 100))%")
                } else {
                    if settingsViewModel.isVideoDownloadEnabled {
                        Button {
                            Task {
                                await playerViewModel.downloadVideo(context: modelContext)
                            }
                        } label: {
                            Label("Videoyu İndir", systemImage: "arrow.down.circle.fill")
                        }
                        .padding()
                        .disabled(playerViewModel.extractYouTubeVideoID(from: video.youtubeURL) == nil)
                    } else {
                        VStack(spacing: 8) {
                            Text("Video İndirme Devre Dışı")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("İndirme özelliğini ayarlardan aktif edebilirsiniz")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Text("Video İndirilmiş")
                        .foregroundColor(.green)
                    
                    HStack(spacing: 16) {
                        Button {
                           playerViewModel.deleteDownloadedVideo(context: modelContext)
                        } label: {
                            Label("Bu Videoyu Sil", systemImage: "trash.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.bordered)
                        
                        NavigationLink {
                            DownloadedVideosView()
                        } label: {
                            Label("Tüm İndirilenler", systemImage: "list.bullet")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            
            if let downloadError = playerViewModel.downloadError {
                Text("İndirme Hatası: \(downloadError)")
                    .foregroundColor(.red)
                    .padding()
            }

            Spacer()
        }
        .navigationTitle("Lineup")
        .onAppear {
            print("🔍 DEBUG: VideoPlayerView onAppear")
            print("🔍 DEBUG: video.localVideoPath: \(video.localVideoPath ?? "nil")")
            print("🔍 DEBUG: video.youtubeURL: \(video.youtubeURL)")
            print("🔍 DEBUG: İnternet bağlantısı: \(networkMonitor.isConnected)")
            
            if let localPath = video.localVideoPath, !localPath.isEmpty {
                print("🔍 DEBUG: Lokal video oynatılacak: \(localPath)")
                let fileExists = FileManager.default.fileExists(atPath: localPath)
                print("🔍 DEBUG: Dosya var mı: \(fileExists)")
                
                if !fileExists {
                    print("❌ DEBUG: Dosya bulunamadı, veritabanı temizlenmeli")
                    video.localVideoPath = nil
                    try? modelContext.save()
                }
            } else if let videoID = playerViewModel.extractYouTubeVideoID(from: video.youtubeURL) {
                print("🔍 DEBUG: YouTube video oynatılacak: \(videoID)")
            } else {
                print("❌ DEBUG: Geçersiz YouTube URL'si: \(video.youtubeURL)")
            }
            
            playerViewModel.checkLocalVideoStatus()
            print("🔍 DEBUG: checkLocalVideoStatus çağrıldı")
            print("🔍 DEBUG: playerViewModel.canPlayLocalVideo: \(playerViewModel.canPlayLocalVideo)")
        }
    }
}

// AVPlayerViewController'ı SwiftUI'da güvenli şekilde göstermek için
struct AVPlayerControllerView: UIViewControllerRepresentable {
    let videoURL: URL
    let onError: (String) -> Void

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        
        // AVPlayer'ı oluştur ve hata dinleyicisi ekle
        let player = AVPlayer(url: videoURL)
        controller.player = player
        controller.showsPlaybackControls = true
        
        // Video yükleme durumunu takip et
        let playerItem = player.currentItem
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            onError("Video oynatılamadı")
        }
        
        // Video hazır olduğunda oynatmaya başla
        playerItem?.addObserver(context.coordinator, forKeyPath: "status", options: [.new], context: nil)
        
        // Player referansını coordinator'a geç
        context.coordinator.player = player
        
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Gerekirse güncelleme yapılabilir
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        let parent: AVPlayerControllerView
        var player: AVPlayer?
        
        init(_ parent: AVPlayerControllerView) {
            self.parent = parent
        }
        
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if keyPath == "status" {
                if let playerItem = object as? AVPlayerItem {
                    switch playerItem.status {
                    case .readyToPlay:
                        print("🔍 DEBUG: Video oynatıma hazır")
                        parent.videoURL.startAccessingSecurityScopedResource()
                        player?.play()
                    case .failed:
                        print("❌ DEBUG: Video yükleme hatası: \(playerItem.error?.localizedDescription ?? "Bilinmeyen hata")")
                        parent.onError("Video yüklenemedi: \(playerItem.error?.localizedDescription ?? "Bilinmeyen hata")")
                    case .unknown:
                        print("🔍 DEBUG: Video durumu bilinmiyor")
                    @unknown default:
                        break
                    }
                }
            }
        }
    }
}

// WKWebView'ı SwiftUI'da kullanmak için UIViewRepresentable struct'ı
struct YouTubeWebView: UIViewRepresentable {
    let videoID: String

    func makeUIView(context: Context) -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor = .black
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Daha basit YouTube embed URL'i
        let embedURL = "https://www.youtube.com/embed/\(videoID)?playsinline=1&modestbranding=1&rel=0"
        
        guard let youtubeURL = URL(string: embedURL) else {
            print("❌ DEBUG: Geçersiz YouTube embed URL'si: \(embedURL)")
            return
        }
        
        print("🔍 DEBUG: YouTube WebView yükleniyor: \(youtubeURL)")
        
        if uiView.url?.absoluteString != youtubeURL.absoluteString {
            let request = URLRequest(url: youtubeURL)
            uiView.load(request)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: YouTubeWebView
        
        init(_ parent: YouTubeWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("🔍 DEBUG: YouTube WebView yüklenmeye başladı")
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("🔍 DEBUG: YouTube WebView yüklendi")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("❌ DEBUG: YouTube WebView yüklenirken hata oluştu (provisional): \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ DEBUG: YouTube WebView yüklenirken hata oluştu (committed): \(error.localizedDescription)")
        }
    }
}
