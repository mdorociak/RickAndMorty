
import Foundation
import ComposableArchitecture
import Models
import Testing
@testable import CharacterDetailFeature

@MainActor
struct CharacterDetailTests {
    @Test
    func loadsEpisodesOnAppear() async {
        let episodes = [Episode.mock(id: 1), Episode.mock(id: 2)]
        let store = TestStore(
            initialState: CharacterDetail.State(character: .mock(id: 1))
        ) {
            CharacterDetail()
        } withDependencies: {
            $0.defaultFileStorage = .inMemory
            $0.apiClient.episodes = { @Sendable _ in episodes }
        }
        await store.send(.onAppear) { $0.episodesState = .loading }
        await store.receive(\.episodesResponse.success) {
            $0.episodes = episodes
            $0.episodesState = .loaded
        }
    }

    @Test
    func episodesLoadFailure() async {
        struct SomeError: Error {}
        let store = TestStore(
            initialState: CharacterDetail.State(character: .mock(id: 1))
        ) {
            CharacterDetail()
        } withDependencies: {
            $0.defaultFileStorage = .inMemory
            $0.apiClient.episodes = { @Sendable _ in throw SomeError() }
        }
        await store.send(.onAppear) { $0.episodesState = .loading }
        await store.receive(\.episodesResponse.failure) {
            $0.episodesState = .failed(SomeError().localizedDescription)
        }
    }

    @Test
    func tappingEpisodeEmitsDelegate() async {
        let episode = Episode.mock(id: 7)
        let store = TestStore(
            initialState: CharacterDetail.State(character: .mock(id: 1))
        ) {
            CharacterDetail()
        } withDependencies: {
            $0.defaultFileStorage = .inMemory
        }
        await store.send(.episodeTapped(episode))
        await store.receive(\.delegate.openEpisode)
    }
}

extension Character {
    static func mock(id: Int, name: String = "Rick") -> Character {
        Character(
            id: id, name: name, status: .alive, species: "Human", type: "",
            gender: .male,
            origin: Location(name: "Earth", urlString: ""),
            location: Location(name: "Earth", urlString: ""),
            imageURL: URL(string: "https://characterdetailtests.com/\(id).png")!,
            episodeIDs: [1, 2]
        )
    }
}

extension Episode {
    static func mock(id: Int) -> Episode {
        Episode(id: id, name: "Pilot", airDate: "December 2, 2013",
                episodeCode: "S01E01", characterIDs: [1, 2])
    }
}
