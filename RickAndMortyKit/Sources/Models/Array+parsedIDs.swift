import Foundation

extension [String] {
    func parsedIDs() -> [Int] {
        compactMap { URL(string: $0)?.lastPathComponent }.compactMap(Int.init)
    }
}
