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
                // AVPlayer ile lokal video oynatma
                LocalVideoPlayerView(videoPath: localPath)
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

// Lokal video oynatmak için AVPlayerViewController wrapper'ı
struct LocalVideoPlayerView: UIViewRepresentable {
    let videoPath: String
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        print("🔍 DEBUG: LocalVideoPlayerView makeUIView")
        print("🔍 DEBUG: videoPath: \(videoPath)")
        
        // Dosya path'ini URL'e çevir
        let fileURL = URL(fileURLWithPath: videoPath)
        print("🔍 DEBUG: fileURL: \(fileURL)")
        
        // Dosyanın var olup olmadığını kontrol et
        guard FileManager.default.fileExists(atPath: videoPath) else {
            print("❌ DEBUG: Video dosyası bulunamadı: \(videoPath)")
            let errorLabel = UILabel()
            errorLabel.text = "Video dosyası bulunamadı"
            errorLabel.textColor = .white
            errorLabel.textAlignment = .center
            errorLabel.frame = view.bounds
            errorLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(errorLabel)
            return view
        }
        
        print("🔍 DEBUG: Video dosyası bulundu")
        
        // Dosya boyutunu kontrol et
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: videoPath)
            let fileSize = attributes[.size] as? Int64 ?? 0
            print("🔍 DEBUG: Dosya boyutu: \(fileSize) bytes")
        } catch {
            print("❌ DEBUG: Dosya özellikleri alınamadı: \(error)")
        }
        
        // Demo video dosyası kontrolü
        do {
            let fileData = try Data(contentsOf: fileURL)
            let fileContent = String(data: fileData, encoding: .utf8)
            
            // Eğer dosya demo içerikse, özel gösterim yap
            if let content = fileContent, content.contains("Demo video content") {
                let demoLabel = UILabel()
                demoLabel.text = "Demo Video\n\nBu video demo amaçlı oluşturulmuştur.\nGerçek uygulamada YouTube video indirme API'si kullanılacaktır."
                demoLabel.textColor = .white
                demoLabel.textAlignment = .center
                demoLabel.numberOfLines = 0
                demoLabel.frame = view.bounds
                demoLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                view.addSubview(demoLabel)
                return view
            }
        } catch {
            print("Dosya okuma hatası: \(error)")
        }
        
        // Gerçek video dosyası için AVPlayer kullan
        let player = AVPlayer(url: fileURL)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.showsPlaybackControls = true
        
        // Player view controller'ı parent view'a ekle
        if let parentViewController = context.coordinator.parentViewController {
            parentViewController.addChild(playerViewController)
            view.addSubview(playerViewController.view)
            playerViewController.view.frame = view.bounds
            playerViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            playerViewController.didMove(toParent: parentViewController)
            
            // Video otomatik olarak başlasın
            player.play()
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // View güncellemeleri burada yapılabilir
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        weak var parentViewController: UIViewController?
        
        override init() {
            super.init()
            // Parent view controller'ı bul
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                findTopViewController(from: rootViewController)
            }
        }
        
        private func findTopViewController(from viewController: UIViewController) {
            if let presented = viewController.presentedViewController {
                findTopViewController(from: presented)
            } else if let navigationController = viewController as? UINavigationController {
                findTopViewController(from: navigationController.visibleViewController ?? navigationController)
            } else if let tabBarController = viewController as? UITabBarController {
                findTopViewController(from: tabBarController.selectedViewController ?? tabBarController)
            } else {
                parentViewController = viewController
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
