import SwiftUI
import Combine

final class OutfitHistoryStore: ObservableObject {
    @Published var outfits: [Outfit] = []
    
    func addOutfit(_ outfit: Outfit) {
        outfits.append(outfit)
    }
    
    func removeOutfit(at index: Int) {
        guard outfits.indices.contains(index) else { return }
        outfits.remove(at: index)
    }
}
