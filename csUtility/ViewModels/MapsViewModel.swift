import SwiftUI

@MainActor
class MapsViewModel: ObservableObject {
    @Published var maps: [CSMap] = CSMap.allCases
}
