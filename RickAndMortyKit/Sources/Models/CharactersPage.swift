public struct CharactersPage: Decodable, Equatable, Sendable {
    public let info: Info
    public let results: [Character]

    public init(info: Info, results: [Character]) {
        self.info = info
        self.results = results
    }

    public struct Info: Equatable, Decodable, Sendable {
        public let count: Int
        public let pages: Int
        public let next: String?
        public let prev: String?

        public init(count: Int, pages: Int, next: String?, prev: String?) {
            self.count = count
            self.pages = pages
            self.next = next
            self.prev = prev
        }
    }
}
