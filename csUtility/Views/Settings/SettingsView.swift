import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsViewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Video Ayarları")) {
                    Toggle("Video İndirme Özelliği", isOn: $settingsViewModel.isVideoDownloadEnabled)
                        .onChange(of: settingsViewModel.isVideoDownloadEnabled) { newValue in
                            if newValue {
                                // Kullanıcıya bilgi ver
                                print("Video indirme özelliği aktif edildi")
                            } else {
                                print("Video indirme özelliği devre dışı bırakıldı")
                            }
                        }
                    
                    Toggle("Lineup Görsellerini Göster", isOn: $settingsViewModel.showThumbnails)
                }
                
                Section(header: Text("Video İndirme Hakkında")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Video İndirme Özelliği")
                            .font(.headline)
                        
                        Text("Bu özellik YouTube videolarını cihazınıza indirmenizi sağlar. İndirilen videolar çevrimdışı izlenebilir.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• İndirilen videolar cihaz depolama alanı kullanır")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• Sadece YouTube videoları indirilebilir")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• İndirme işlemi internet bağlantısı gerektirir")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section {
                    Button("Varsayılan Ayarlara Sıfırla") {
                        settingsViewModel.resetToDefaults()
                    }
                    .foregroundColor(.orange)
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tamam") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
} 