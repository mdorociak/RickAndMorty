import SwiftUI
import ComposableArchitecture
import CharactersListFeature

public struct RootView: View {
    public init() {}

    public var body: some View {
        CharactersListView(
            store: Store(initialState: CharactersList.State()) {
                CharactersList()
            }
        )
    }
}
