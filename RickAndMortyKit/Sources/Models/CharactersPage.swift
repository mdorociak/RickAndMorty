
import Foundation

public struct CharactersPage: Decodable, Equatable, Sendable {
    public let info: Info
    public let results: [Character]
    
    public struct Info: Equatable, Decodable, Sendable {
        public let count: Int
        public let pages: Int
        public let next: String?
        public let prev: String?
    }
}

