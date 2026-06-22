
import Foundation

public struct Character: Decodable, Sendable, Identifiable, Equatable {
    
    public let id: Int
    public let name: String
    public let status: Status
    public let species: String
    public let type: String
    public let gender: Gender
    public let origin: Location
    public let location: Location
    public let imageURL: URL
    public let episodeIDs: [Int]
    
    
    private enum CodingKeys: String, CodingKey {
        case id, name, status, species, type, gender, origin, location
        case imageURL = "image"
        case episodeIDs = "episode"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.status = try container.decode(Status.self, forKey: .status)
        self.species = try container.decode(String.self, forKey: .species)
        self.type = try container.decode(String.self, forKey: .type)
        self.gender = try container.decode(Gender.self, forKey: .gender)
        self.origin = try container.decode(Location.self, forKey: .origin)
        self.location = try container.decode(Location.self, forKey: .location)
        self.imageURL = try container.decode(URL.self, forKey: .imageURL)
        
        let urlStrings = try container.decode([String].self, forKey: .episodeIDs)
        self.episodeIDs = urlStrings.parsedIDs()
    }
    
    public init(
        id: Int,
        name: String,
        status: Status,
        species: String,
        type: String,
        gender: Gender,
        origin: Location,
        location: Location,
        imageURL: URL,
        episodeIDs: [Int]
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.species = species
        self.type = type
        self.gender = gender
        self.origin = origin
        self.location = location
        self.imageURL = imageURL
        self.episodeIDs = episodeIDs
    }
}

public struct Location: Decodable, Equatable, Sendable {
    public let name: String
    public let urlString: String
    
    public var url: URL? {
        URL(string: urlString)
    }
    
    public init(name: String, urlString: String) {
        self.name = name
        self.urlString = urlString
    }
    
    private enum CodingKeys: String, CodingKey {
        case name
        case urlString = "url"
    }
}

public enum Status: String, Decodable, Sendable {
    case alive = "Alive"
    case dead = "Dead"
    case unknown
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = Status(rawValue: raw) ?? .unknown
    }
}

public enum Gender: String, Decodable, Sendable {
    case male = "Male"
    case female = "Female"
    case genderless = "Genderless"
    case unknown
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = Gender(rawValue: raw) ?? .unknown
    }
}
