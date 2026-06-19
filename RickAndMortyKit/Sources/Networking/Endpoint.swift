import Foundation

enum Endpoint {
    case characters(page: Int, name: String?)
    case episode(id: Int)
    case episodes(ids: [Int])

    private static let baseURL = "https://rickandmortyapi.com/api"

    var url: URL? {
        guard var components = URLComponents(string: Self.baseURL) else {
            return nil
        }

        switch self {
        case let .characters(page, name):
            components.path += "/character/"

            var queryItems = [
                URLQueryItem(name: "page", value: String(page))
            ]

            if let name, !name.isEmpty {
                queryItems.append(URLQueryItem(name: "name", value: name))
            }

            components.queryItems = queryItems

        case let .episode(id):
            components.path += "/episode/\(id)"

        case let .episodes(ids):
            let idsPath = ids.map(String.init).joined(separator: ",")
            components.path += "/episode/\(idsPath)"
        }

        return components.url
    }
}
