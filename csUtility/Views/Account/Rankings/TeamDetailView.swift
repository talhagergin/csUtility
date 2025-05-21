// Views/Rankings/TeamDetailView.swift (Yeni dosya)
import SwiftUI

struct TeamDetailView: View {
    let team: TeamRanking

    var body: some View {
        List {
            Section {
                HStack {
                    if let logoName = team.logoName, !logoName.isEmpty {
                        Image(logoName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .padding(.trailing, 5)
                    }
                    VStack(alignment: .leading) {
                        Text(team.teamName)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("#\(team.rank) - \(team.points) puan")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Takım Bilgisi")
            }

            Section {
                if team.players.isEmpty {
                    Text("Oyuncu bilgisi bulunmamaktadır.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(team.players) { player in
                        PlayerRowView(player: player)
                    }
                }
            } header: {
                Text("Oyuncular (\(team.players.count))")
            }
        }
        .navigationTitle(team.teamName)
        // .navigationBarTitleDisplayMode(.inline) // İsteğe bağlı
    }
}
