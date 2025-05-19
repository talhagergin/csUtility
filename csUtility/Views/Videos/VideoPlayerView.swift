// VideoPlayerView.swift

import SwiftUI
import WebKit // YouTubeWebView için
import SwiftData // modelContext için

// ASIL VideoPlayerView STRUCT'I BU
struct VideoPlayerView: View {
    let video: LineupVideo // Artık @ObservedObject değil

    @StateObject private var playerViewModel: VideoPlayerViewModel
    @Environment(\.modelContext) private var modelContext

    init(video: LineupVideo) {
        self.video = video
        _playerViewModel = StateObject(wrappedValue: VideoPlayerViewModel(video: video))
    }
    
    var body: some View {
        VStack {
            if let localPath = video.localVideoPath, !localPath.isEmpty, playerViewModel.canPlayLocalVideo {
                // AVPlayer ile lokal video oynatma (Bu kısım ayrıca implemente edilmeli)
                Text("Yerel video oynatılıyor: \(localPath)")
                // TODO: AVPlayerViewControllerRepresentable oluşturup lokal videoyu oynat
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
                    Button {
                        Task {
                            await playerViewModel.downloadVideo(context: modelContext)
                        }
                    } label: {
                        Label("Videoyu İndir", systemImage: "arrow.down.circle.fill")
                    }
                    .padding()
                    .disabled(playerViewModel.extractYouTubeVideoID(from: video.youtubeURL) == nil)
                }
            } else {
                Text("Video İndirilmiş")
                    .foregroundColor(.green)
                Button {
                   playerViewModel.deleteDownloadedVideo(context: modelContext)
                } label: {
                    Label("İndirilen Videoyu Sil", systemImage: "trash.fill")
                        .foregroundColor(.red)
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
            playerViewModel.checkLocalVideoStatus()
        }
    }
}

// WKWebView'ı SwiftUI'da kullanmak için UIViewRepresentable struct'ı
// BU STRUCT ZATEN SİZDE VAR (BİRAZ ÖNCE PAYLAŞTIĞINIZ KOD)
struct YouTubeWebView: UIViewRepresentable {
    let videoID: String

    func makeUIView(context: Context) -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let youtubeURL = URL(string: "https://www.youtube.com/embed/\(videoID)?playsinline=1&modestbranding=1&rel=0") else {
            print("Geçersiz YouTube embed URL'si")
            return
        }
        if uiView.url?.absoluteString != youtubeURL.absoluteString {
            uiView.load(URLRequest(url: youtubeURL))
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
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("YouTube WebView yüklenirken hata oluştu (provisional): \(error.localizedDescription)")
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("YouTube WebView yüklenirken hata oluştu (committed): \(error.localizedDescription)")
        }
    }
}
