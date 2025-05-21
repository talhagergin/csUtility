// Views/Rankings/TeamRowView.swift (Yeni dosya)
import SwiftUI

struct TeamRowView: View {
    let team: TeamRanking

    var body: some View {
        HStack(spacing: 12) {
            Text("#\(team.rank)")
                .font(.headline)
                .frame(width: 35, alignment: .leading)

            if let logoName = team.logoName, !logoName.isEmpty {
                Image(logoName) // Assets'e eklenmiş takım logoları
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .clipShape(Circle()) // Veya RoundedRectangle(cornerRadius: 4)
            } else {
                Image(systemName: "shield.lefthalf.filled") // Varsayılan logo
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.gray)
            }

            VStack(alignment: .leading) {
                Text(team.teamName)
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                Text("\(team.points) puan")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let change = team.rankChange, change != 0 {
                Text(team.rankChangeDisplay.text)
                    .font(.caption.bold())
                    .foregroundColor(team.rankChangeDisplay.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(team.rankChangeDisplay.color.opacity(0.15))
                    .clipShape(Capsule())
            } else if team.rankChange == 0 {
                 Text("-")
                    .font(.caption.bold())
                    .foregroundColor(.gray)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 8)
    }
}
