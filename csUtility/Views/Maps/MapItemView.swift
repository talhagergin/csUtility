// MapItemView.swift

import SwiftUI

struct MapItemView: View {
    let map: CSMap // CSMap enum'ından bir harita alacak

    var body: some View {
        VStack(spacing: 8) { // Dikeyde elemanlar arası boşluk
            Image(map.imageName) // CSMap enum'ında tanımladığımız resim adı
                .resizable()
                .aspectRatio(contentMode: .fit) // Veya .scaledToFit() de kullanılabilir
                // .scaledToFill() kullanırsanız ve bir frame verirseniz, taşan kısımları .clipped() ile kesmeniz gerekebilir.
                .frame(height: 100) // Resmin yüksekliğini sabitliyoruz, genişlik orantılı ayarlanacak
                .cornerRadius(8)    // Köşeleri yuvarlatıyoruz
                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2) // Hafif bir gölge

            Text(map.displayName) // CSMap enum'ında tanımladığımız görünen ad
                .font(.headline)    // Başlık fontu
                .foregroundColor(.primary) // Metin rengi (sistem temasına göre değişir)
                .lineLimit(1)       // Uzun harita isimleri için tek satırda kalmasını sağlar
                .minimumScaleFactor(0.8) // Eğer sığmazsa fontu biraz küçültür
        }
        .padding(12) // İçeriden her yöne boşluk
        .background(Color(UIColor.systemGray6)) // iOS'un standart açık gri arka planlarından biri
        // .background(.thinMaterial) // iOS 15+ için modern, yarı saydam bir arka plan da olabilir
        .cornerRadius(12) // Tüm item'ın köşelerini yuvarlatıyoruz
        // .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3) // Item'a genel bir gölge (opsiyonel)
    }
}

struct MapItemView_Previews: PreviewProvider {
    static var previews: some View {
        // Önizleme için birkaç farklı harita ile deneyebiliriz
        // ve farklı layout boyutlarında nasıl göründüğüne bakabiliriz.
        Group {
            MapItemView(map: .dust2)
                .previewLayout(.fixed(width: 200, height: 200))
                .padding()

            MapItemView(map: .inferno)
                .previewLayout(.fixed(width: 180, height: 180))
                .padding()
            
            // Dark mode'da nasıl göründüğünü de test edebiliriz
            MapItemView(map: .mirage)
                .previewLayout(.sizeThatFits)
                .padding()
                .preferredColorScheme(.dark)
        }
    }
}
