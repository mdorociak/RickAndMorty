import ComposableArchitecture

public extension SharedKey where Self == FileStorageKey<Set<Int>>.Default {
    static var favoriteIDs: Self {
        Self[.fileStorage(.documentsDirectory.appending(component: "favorites.json")), default: []]
    }
}
