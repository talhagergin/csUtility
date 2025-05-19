import SwiftUI
import SwiftData

struct NewsListView: View {
    @Query(sort: [SortDescriptor(\NewsItem.publishedDate, order: .reverse)]) private var newsItems: [NewsItem]
    // Alternatif olarak ViewModel kullanılabilir
    // @StateObject private var viewModel: NewsViewModel
    
    @Environment(\.modelContext) private var modelContext // Silme işlemi için

    init(modelContext: ModelContext? = nil) {
        // Eğer ViewModel kullanılıyorsa:
        // _viewModel = StateObject(wrappedValue: NewsViewModel(modelContext: modelContext ?? AppModelContainer.shared.mainContext))
    }

    var body: some View {
        Group {
            if newsItems.isEmpty {
                Text("Henüz haber bulunmamaktadır.")
                    .foregroundColor(.secondary)
            } else {
                List {
                    ForEach(newsItems) { item in
                        NewsItemView(newsItem: item)
                    }
                    // .onDelete(perform: deleteItems) // Admin için silme eklenebilir
                }
            }
        }
        .navigationTitle("Haberler")
    }
    
    // private func deleteItems(offsets: IndexSet) {
    //     withAnimation {
    //         offsets.map { newsItems[$0] }.forEach(modelContext.delete)
    //     }
    // }
}

struct NewsItemView: View {
    let newsItem: NewsItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageURLString = newsItem.imageURL, let url = URL(string: imageURLString) {
                // AsyncImage ile uzaktan görsel yükleme (iOS 15+)
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable()
                             .aspectRatio(contentMode: .fit)
                             .cornerRadius(8)
                    } else if phase.error != nil {
                        Color.gray.frame(height: 150).cornerRadius(8) // Hata durumunda placeholder
                            .overlay(Text("Görsel Yüklenemedi").foregroundColor(.white))
                    } else {
                        ProgressView().frame(height: 150) // Yüklenirken
                    }
                }
                .frame(maxWidth: .infinity, idealHeight: 200)

            }
            Text(newsItem.title)
                .font(.headline)
            Text(newsItem.content)
                .font(.subheadline)
                .lineLimit(3) // İçeriği kısalt
            HStack {
                Text(newsItem.publishedDate, style: .date)
                Spacer()
                Text("Yazar: \(newsItem.author ?? "Bilinmiyor")")
            }
            .font(.caption)
            .foregroundColor(.gray)
        }
        .padding(.vertical, 5)
    }
}
