
import Foundation

public struct Episode: Decodable, Equatable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let airDate: String
    public let episodeCode: String
    public let characterIDs: [Int]
    
    private enum CodingKeys: String, CodingKey {
        case id, name
        case airDate = "air_date"
        case episodeCode = "episode"
        case characterIDs = "characters"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.airDate = try container.decode(String.self, forKey: .airDate)
        self.episodeCode = try container.decode(String.self, forKey: .episodeCode)
        
        let urlStrings = try container.decode([String].self, forKey: .characterIDs)
        self.characterIDs = urlStrings.parsedIDs()
    }
}
