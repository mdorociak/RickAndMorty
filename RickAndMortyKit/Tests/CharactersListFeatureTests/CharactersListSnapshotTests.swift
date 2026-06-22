
import SnapshotTesting
import Testing
import SwiftUI
import ComposableArchitecture
import Models
@testable import CharactersListFeature

@MainActor
struct CharactersListSnapshotTests {
    @Test
    func loadingState() {
        let store = Store(initialState: CharactersList.State()) {
            CharactersList()
        } withDependencies: {
            $0.defaultFileStorage = .inMemory
            $0.apiClient.characters = { @Sendable _, _ in
                try await Task.never()
            }
        }
        
        let view = CharactersListView(store: store)
        
        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }
    @Test
    func emptyState() {
        var state = CharactersList.State()
        state.loadingState = .empty
        let store = Store(initialState: state) {
            CharactersList()
        } withDependencies: {
            $0.defaultFileStorage = .inMemory
        }
        let view = CharactersListView(store: store)
        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }

    @Test
    func errorState() {
        var state = CharactersList.State()
        state.loadingState = .failed("Something went wrong")
        let store = Store(initialState: state) {
            CharactersList()
        } withDependencies: {
            $0.defaultFileStorage = .inMemory
        }
        let view = CharactersListView(store: store)
        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13)))
    }

    @Test
    func loadedState() {
        var state = CharactersList.State()
        state.loadingState = .loaded
        state.characters = [.mock(id: 1, name: "Rick"), .mock(id: 2, name: "Morty")]
        let store = Store(initialState: state) {
            CharactersList()
        } withDependencies: {
            $0.defaultFileStorage = .inMemory
        }
        let view = CharactersListView(store: store)
        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }
}
