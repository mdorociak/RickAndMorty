
import Foundation
import ComposableArchitecture
import Models
import Testing
@testable import CharactersListFeature

@MainActor
struct CharactersListTests {
    @Test
    func loadsFirstPageOnAppear() async {
        let page = CharactersPage(
            info: .init(count: 1, pages: 1, next: nil, prev: nil),
            results: [.mock(id: 1, name: "Rick")]
        )
        let store = TestStore(initialState: CharactersList.State()) {
            CharactersList()
        } withDependencies: {
            $0.defaultFileStorage = .inMemory
            $0.apiClient.characters = { @Sendable _, _ in page }
        }

        await store.send(.onAppear) {
            $0.loadingState = .loading
        }
        await store.receive(\.charactersResponse.success) {
            $0.characters = [.mock(id: 1, name: "Rick")]
            $0.charactersByID = [1: .mock(id: 1, name: "Rick")]
            $0.currentPage = 1
            $0.hasMorePages = false
            $0.loadingState = .loaded
        }
    }
    
    @Test
    func loadsEmptyResults() async {
        let page = CharactersPage(info: .init(count: 0, pages: 0, next: nil, prev: nil), results: [])
        let store = TestStore(initialState: CharactersList.State()) {
            CharactersList()
        } withDependencies: {
            $0.apiClient.characters = { @Sendable _, _ in page }
        }
        await store.send(.onAppear) { $0.loadingState = .loading }
        await store.receive(\.charactersResponse.success) {
            $0.hasMorePages = false
            $0.loadingState = .empty
        }
    }
    
    @Test
    func loadFailure() async {
        struct SomeError: Error {}
        let store = TestStore(initialState: CharactersList.State()) {
            CharactersList()
        } withDependencies: {
            $0.apiClient.characters = { @Sendable _, _ in throw SomeError() }
        }
        await store.send(.onAppear) { $0.loadingState = .loading }
        await store.receive(\.charactersResponse.failure) {
            $0.loadingState = .failed(SomeError().localizedDescription)
        }
    }
    
    @Test
    func favoriteToggle() async {
        let store = TestStore(initialState: CharactersList.State()) {
            CharactersList()
        } withDependencies: {
            $0.defaultFileStorage = .inMemory
        }
        let character = Character.mock(id: 1)
        await store.send(.favoriteToggled(character)) {
            $0.$favoriteIDs.withLock { $0 = [1] }
        }
        await store.send(.favoriteToggled(character)) {
            $0.$favoriteIDs.withLock { $0 = [] }
        }
    }
    
    @Test
    func searchDebounces() async {
        let clock = TestClock()
        let page = CharactersPage(info: .init(count: 1, pages: 1, next: nil, prev: nil),
                                  results: [.mock(id: 5, name: "Morty")])
        let store = TestStore(initialState: CharactersList.State()) {
            CharactersList()
        } withDependencies: {
            $0.continuousClock = clock
            $0.apiClient.characters = { @Sendable _, _ in page }
        }
        await store.send(.binding(.set(\.searchText, "morty"))) {
            $0.searchText = "morty"
            $0.isLoadingNextPage = false
        }
        await clock.advance(by: .milliseconds(300))
        await store.receive(\.charactersResponse.success) {
            $0.characters = [.mock(id: 5, name: "Morty")]
            $0.charactersByID = [5: .mock(id: 5, name: "Morty")]
            $0.currentPage = 1
            $0.hasMorePages = false
            $0.loadingState = .loaded
        }
    }
    @Test
    func searchCancelsPreviousRequests() async {
        let clock = TestClock()
        let page = CharactersPage(
            info: .init(count: 1, pages: 1, next: nil, prev: nil),
            results: [.mock(id: 1, name: "Rick")]
        )
        let requests = LockIsolated<[String?]>([])
        let store = TestStore(initialState: CharactersList.State()) {
            CharactersList()
        } withDependencies: {
            $0.continuousClock = clock
            $0.defaultFileStorage = .inMemory
            $0.apiClient.characters = { @Sendable _, name in
                requests.withValue { $0.append(name) }
                return page
            }
        }
        await store.send(.binding(.set(\.searchText, "r"))) {
            $0.searchText = "r"
        }
        await store.send(.binding(.set(\.searchText, "ri"))) {
            $0.searchText = "ri"
        }
        await store.send(.binding(.set(\.searchText, "rick"))) {
            $0.searchText = "rick"
        }
        await clock.advance(by: .milliseconds(300))
        await store.receive(\.charactersResponse.success) {
            $0.characters = [.mock(id: 1, name: "Rick")]
            $0.charactersByID = [1: .mock(id: 1, name: "Rick")]
            $0.loadingState = .loaded
        }
        #expect(requests.value == ["rick"])
    }

    @Test
    func paginationAppendsNextPage() async {
        let page = CharactersPage(
            info: .init(
                count: 2,
                pages: 2,
                next: nil,
                prev: "page=1"
            ),
            results: [
                .mock(id: 2, name: "Morty")
            ]
        )
        let store = TestStore(
            initialState: {
                var state = CharactersList.State()
                state.characters = [.mock(id: 1, name: "Rick")]
                state.currentPage = 1
                state.hasMorePages = true
                return state
            }()
        ) {
            CharactersList()
        } withDependencies: {
            $0.defaultFileStorage = .inMemory
            $0.apiClient.characters = { @Sendable pageNumber, _ in
                #expect(pageNumber == 2)
                return page
            }
        }
        await store.send(.characterAppeared(1)) {
            $0.isLoadingNextPage = true
        }
        await store.receive(\.nextPageResponse.success) {
            $0.characters.append(.mock(id: 2, name: "Morty"))
            $0.charactersByID = [2: .mock(id: 2, name: "Morty")]
            $0.currentPage = 2
            $0.hasMorePages = false
            $0.isLoadingNextPage = false
        }
    }

    @Test
    func characterAppearedWhileLoadingDoesNothing() async {
        let store = TestStore(
            initialState: {
                var state = CharactersList.State()
                state.characters = [.mock(id: 1)]
                state.isLoadingNextPage = true
                state.hasMorePages = true
                return state
            }()
        ) {
            CharactersList()
        } withDependencies: {
            $0.defaultFileStorage = .inMemory
        }
        await store.send(.characterAppeared(1))
        await store.finish()
    }
    @Test
    func characterAppearedWithNoMorePagesDoesNothing() async {
        let store = TestStore(
            initialState: {
                var state = CharactersList.State()
                state.characters = [.mock(id: 1)]
                state.hasMorePages = false
                return state
            }()
        ) {
            CharactersList()
        } withDependencies: {
            $0.defaultFileStorage = .inMemory
        }
    await store.send(.characterAppeared(1))
    await store.finish()
    }
}

extension Character {
    static func mock(id: Int, name: String = "Rick") -> Character {
        Character(
            id: id,
            name: name,
            status: .alive,
            species: "Human",
            type: "",
            gender: .male,
            origin: Location(name: "Earth", urlString: ""),
            location: Location(name: "Earth", urlString: ""),
            imageURL: URL(string: "https://characterslisttests.com/\(id).png")!,
            episodeIDs: [1, 2]
        )
    }
}
