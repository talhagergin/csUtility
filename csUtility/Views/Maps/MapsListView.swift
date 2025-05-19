import SwiftUI

struct MapsListView: View {
    @ObservedObject var viewModel: MapsViewModel

    let columns = [GridItem(.adaptive(minimum: 150))]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(viewModel.maps) { map in
                    NavigationLink(value: map) {
                        MapItemView(map: map)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Haritalar")
        .navigationDestination(for: CSMap.self) { map in
            MapDetailView(map: map)
        }
    }
}

struct MapItemView: View {
    let map: CSMap

    var body: some View {
        VStack {
            Image(map.imageName) // Assets'e eklenmiş olmalı
                .resizable()
                .scaledToFit()
                .frame(height: 100)
                .cornerRadius(8)
                .shadow(radius: 3)
            Text(map.displayName)
                .font(.headline)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
