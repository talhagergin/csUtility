// Views/Rankings/PlayerRowView.swift (Yeni dosya)
import SwiftUI

struct PlayerRowView: View {
    let player: PlayerInfo

    var body: some View {
        HStack {
            Text(flag(country: player.countryCode)) // Bayrak emojisi
                .font(.title) // Bayrak boyutunu ayarlar
                .frame(width: 30, alignment: .center)


            Text(player.playerName)
                .font(.body)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
