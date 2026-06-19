import Foundation
import ComposableArchitecture
import Models

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is invalid"
        case .invalidResponse:
            return "The server returned an invalid response"
        case .httpStatus(let statusCode):
            return "The server returned HTTP \(statusCode)"
        }
    }
}

@DependencyClient
public struct APIClient: Sendable {
    public var characters: @Sendable (_ page: Int, _ name: String?) async throws -> CharactersPage
    public var episode: @Sendable (_ id: Int) async throws -> Episode
    public var episodes: @Sendable (_ ids: [Int]) async throws -> [Episode]
}



extension APIClient: DependencyKey {
    public static let liveValue = APIClient(
        characters: { page, name in
            try await fetch(
                .characters(page: page, name: name),
                as: CharactersPage.self)
        },
        episode: { id in
            try await fetch(
                .episode(id: id),
                as: Episode.self)
        }, episodes: { ids in
            guard !ids.isEmpty else { return [] }
            if ids.count == 1, let id = ids.first {
                let episode = try await fetch(.episode(id: id), as: Episode.self)
                return [episode]
            }
            return try await fetch(.episodes(ids: ids), as: [Episode].self)
        }
    )
}

extension DependencyValues {
    public var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}

private func fetch<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
    guard let url = endpoint.url else { throw APIError.invalidURL }
    
    let (data, response) = try await URLSession.shared.data(from: url)
    
    guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
    
    guard 200..<300 ~= httpResponse.statusCode else {
        throw APIError.httpStatus(httpResponse.statusCode)
    }
    
    let decoder = JSONDecoder()
    return try decoder.decode(T.self, from: data)
}
