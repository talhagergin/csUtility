import SwiftUI
import Foundation

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var isVideoDownloadEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isVideoDownloadEnabled, forKey: "isVideoDownloadEnabled")
        }
    }
    
    @Published var showThumbnails: Bool {
        didSet {
            UserDefaults.standard.set(showThumbnails, forKey: "showThumbnails")
        }
    }
    
    init() {
        // UserDefaults'tan ayarları yükle
        self.isVideoDownloadEnabled = UserDefaults.standard.bool(forKey: "isVideoDownloadEnabled")
        self.showThumbnails = UserDefaults.standard.bool(forKey: "showThumbnails")
        
        // İlk kez açılıyorsa varsayılan değerleri ayarla
        if !UserDefaults.standard.bool(forKey: "hasSetDefaultSettings") {
            self.isVideoDownloadEnabled = false // Varsayılan olarak kapalı
            self.showThumbnails = true // Varsayılan olarak açık
            UserDefaults.standard.set(true, forKey: "hasSetDefaultSettings")
        }
    }
    
    func resetToDefaults() {
        isVideoDownloadEnabled = false
        showThumbnails = true
        UserDefaults.standard.set(true, forKey: "hasSetDefaultSettings")
    }
} 