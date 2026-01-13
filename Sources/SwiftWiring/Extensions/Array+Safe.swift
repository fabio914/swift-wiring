import Foundation

extension Array {
    func safeIndex(_ index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
