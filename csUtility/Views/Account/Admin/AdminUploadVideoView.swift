import SwiftUI
import SwiftData

struct AdminUploadVideoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var accountViewModel: AccountViewModel // Admin kontrolü için

    @State private var title: String = ""
    @State private var youtubeURL: String = ""
    @State private var selectedMap: CSMap
    @State private var selectedUtility: UtilityType
    
    @State private var showAlert = false
    @State private var alertMessage = ""

    let onUploadComplete: () -> Void // Yükleme tamamlandığında çağrılacak closure

    init(map: CSMap, utilityType: UtilityType, onUploadComplete: @escaping () -> Void) {
        _selectedMap = State(initialValue: map)
        _selectedUtility = State(initialValue: utilityType)
        self.onUploadComplete = onUploadComplete
    }

    var body: some View {
        NavigationView { // .toolbar kullanımı için NavigationView veya NavigationStack içinde olmalı
            Form {
                Section(header: Text("Video Detayları")) {
                    TextField("Video Başlığı", text: $title)
                    TextField("YouTube Video Linki", text: $youtubeURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }

                Section(header: Text("Kategorizasyon")) {
                    Picker("Harita Seç", selection: $selectedMap) {
                        ForEach(CSMap.allCases) { map in
                            Text(map.displayName).tag(map)
                        }
                    }
                    Picker("Utility Tipi Seç", selection: $selectedUtility) {
                        ForEach(UtilityType.allCases) { utility in
                            Text(utility.rawValue).tag(utility)
                        }
                    }
                }

                Button("Videoyu Yükle") {
                    saveVideo()
                }
            }
            .navigationTitle("Yeni Lineup Yükle")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Bilgi"), message: Text(alertMessage), dismissButton: .default(Text("Tamam")) {
                    if alertMessage.contains("başarıyla eklendi") {
                        dismiss()
                    }
                })
            }
            .onAppear {
                guard accountViewModel.isAdmin else {
                    // Eğer admin değilse, bu ekrana erişimi engelle veya uyarı göster.
                    // Pratikte bu view'a yönlendirme admin kontrolü ile yapılmalı.
                    alertMessage = "Bu alanı görüntüleme yetkiniz yok."
                    showAlert = true
                    // dismiss() // hemen kapatmak için
                    return
                }
            }
        }
    }

    private func saveVideo() {
        guard !title.isEmpty, !youtubeURL.isEmpty else {
            alertMessage = "Başlık ve YouTube linki boş bırakılamaz."
            showAlert = true
            return
        }
        
        guard let _ = URL(string: youtubeURL), (youtubeURL.contains("youtube.com") || youtubeURL.contains("youtu.be")) else {
            alertMessage = "Lütfen geçerli bir YouTube linki girin."
            showAlert = true
            return
        }

        let newVideo = LineupVideo(
            title: title,
            youtubeURL: youtubeURL,
            mapName: selectedMap.rawValue,
            utilityType: selectedUtility,
            uploadedDate: Date(),
            uploaderID: accountViewModel.loggedInUser?.username // Veya ID
        )

        modelContext.insert(newVideo)

        do {
            try modelContext.save()
            alertMessage = "Video başarıyla eklendi!"
            onUploadComplete() // Liste yenileme için callback çağır
            // dismiss() // Alert gösterdikten sonra kapatmak daha iyi
        } catch {
            alertMessage = "Video kaydedilirken hata oluştu: \(error.localizedDescription)"
        }
        showAlert = true
    }
}
