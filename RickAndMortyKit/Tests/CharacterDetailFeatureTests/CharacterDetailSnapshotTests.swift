
import SnapshotTesting
import Testing
import SwiftUI
import ComposableArchitecture
import Models
@testable import CharacterDetailFeature

@MainActor
struct CharacterDetailSnapshotTests {
    @Test
    func episodesLoaded() {
        var state = CharacterDetail.State(character: .mock(id: 1, name: "Rick"))
        state.episodes = [.mock(id: 1), .mock(id: 2)]
        state.episodesState = .loaded
        let store = Store(initialState: state) {
            CharacterDetail()
        } withDependencies: {
            $0.defaultFileStorage = .inMemory
        }
        let view = NavigationStack {
            CharacterDetailsView(store: store)
        }
        .frame(width: 393, height: 852)
        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }

    @Test
    func episodesLoading() {
        var state = CharacterDetail.State(character: .mock(id: 1, name: "Rick"))
        state.episodesState = .loading
        let store = Store(initialState: state) {
            CharacterDetail()
        } withDependencies: {
            $0.defaultFileStorage = .inMemory
        }
        let view = NavigationStack {
            CharacterDetailsView(store: store)
        }
        .frame(width: 393, height: 852)
        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }
}
