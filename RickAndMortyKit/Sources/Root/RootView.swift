import SwiftUI
import ComposableArchitecture
import CharactersListFeature

public struct RootView: View {
    @State private var store = Store(initialState: CharactersList.State()) {
        CharactersList()
    }
    public init() {}
    public var body: some View {
        CharactersListView(store: store)
    }
}
