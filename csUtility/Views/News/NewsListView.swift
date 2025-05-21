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

