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

    init(video: LineupVideo) {
        self.video = video
        _playerViewModel = StateObject(wrappedValue: VideoPlayerViewModel(video: video))
    }
    
    var body: some View {
        VStack {
            if let localPath = video.localVideoPath, !localPath.isEmpty {
                let fileURL = URL(fileURLWithPath: localPath)
                AVPlayerControllerView(videoURL: fileURL)
                    .frame(minHeight: 200, idealHeight: 300)
                    .cornerRadius(8)
            } else if let videoID = playerViewModel.extractYouTubeVideoID(from: video.youtubeURL) {
                // BURADA YouTubeWebView ÇAĞRILIYOR
                YouTubeWebView(videoID: videoID)
                    .frame(minHeight: 200, idealHeight: 300)
            } else {
                Text("Geçersiz YouTube URL'si")
                    .foregroundColor(.red)
            }

            Text(video.title)
                .font(.title2)
                .padding()

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
            
            if let localPath = video.localVideoPath, !localPath.isEmpty {
                print("🔍 DEBUG: Lokal video oynatılacak: \(localPath)")
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

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = AVPlayer(url: videoURL)
        controller.showsPlaybackControls = true
        controller.player?.play()
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Gerekirse güncelleme yapılabilir
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
