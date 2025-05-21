// Views/Rankings/RankingsListView.swift (Yeni klasör ve dosya)
import SwiftUI
import SwiftData

struct RankingsListView: View {
    // Verileri tarihe ve sonra rank'a göre sırala
    @Query(sort: [SortDescriptor(\TeamRanking.lastUpdated, order: .reverse), SortDescriptor(\TeamRanking.rank)])
    private var teams: [TeamRanking]
    
    // Veya sadece rank'a göre:
    // @Query(sort: \TeamRanking.rank) private var teams: [TeamRanking]


    @State private var showingInfoAlert = false

    var body: some View {
        NavigationView { // Her tab kendi NavigationView'ına sahip olabilir
            if teams.isEmpty {
                ContentUnavailableView(
                    "Sıralama Yok",
                    systemImage: "list.star",
                    description: Text("Henüz görüntülenecek takım sıralaması bulunmamaktadır.")
                )
            } else {
                List {
                    // Son güncelleme tarihini göstermek için (opsiyonel)
                    if let firstTeam = teams.first {
                        Section {
                            Text("Son Güncelleme: \(firstTeam.lastUpdated, style: .date) \(firstTeam.lastUpdated, style: .time)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }

                    ForEach(teams) { team in
                        NavigationLink(destination: TeamDetailView(team: team)) {
                            TeamRowView(team: team)
                        }
                    }
                }
                .listStyle(.plain) // Veya .insetGrouped
                .navigationTitle("Takım Sıralaması")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingInfoAlert = true
                        } label: {
                            Image(systemName: "info.circle")
                        }
                    }
                }
                .alert("Sıralama Bilgisi", isPresented: $showingInfoAlert) {
                    Button("Tamam", role: .cancel) { }
                } message: {
                    Text("Bu sıralamalar örneğin HLTV.org gibi kaynaklardan alınmıştır ve düzenli olarak güncellenir (simüle edilmiştir).")
                }
            }
        }
    }
}

struct RankingsListView_Previews: PreviewProvider {
    static var previews: some View {
        // Önizleme için örnek verilerle dolu bir model container sağlamak gerekir.
        // Şimdilik boş bir liste veya placeholder gösterelim.
        RankingsListView()
            .modelContainer(AppModelContainer.shared) // Örnek container ile
    }
}
