import SwiftUI
import SwiftData // modelContext için eklendi

struct MapDetailView: View {
    let map: CSMap
    let utilityTypes = UtilityType.allCases
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            ForEach(utilityTypes) { utility in
                NavigationLink(value: UtilitySelection(map: map, utility: utility)) {
                    HStack {
                        Image(systemName: utility.iconName)
                            .foregroundColor(.accentColor)
                        Text(utility.rawValue)
                    }
                }
            }
        }
        .navigationTitle(map.displayName)
        .navigationDestination(for: UtilitySelection.self) { selection in
            // Düzeltilmiş ViewModel adı: LineupVideosViewModel
            LineupVideosListView(
                viewModel: LineupVideosViewModel( // Burası LineupVideosListViewModel DEĞİL, LineupVideosViewModel olacak
                    modelContext: modelContext,
                    map: selection.map,
                    utility: selection.utility
                )
            )
        }
    }
}

// Navigation için helper struct (bu doğruydu)
struct UtilitySelection: Hashable {
    let map: CSMap
    let utility: UtilityType
}
