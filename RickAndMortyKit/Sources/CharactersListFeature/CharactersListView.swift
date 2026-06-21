
import ComposableArchitecture
import SwiftUI
import Models
import SharedUI
import CharacterDetailFeature

@MainActor
public struct CharactersListView: View {
    @Bindable var store: StoreOf<CharactersList>
    
    public init(store: StoreOf<CharactersList>) {
        self.store = store
    }
    
    public var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            Group {
                switch store.loadingState {
                case .idle, .loading:
                    ProgressView("Loading characters")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .loaded:
                    List {
                        ForEach(Array(store.characters.enumerated()), id: \.element.id) { index, character in
                            Button {
                                store.send(.characterTapped(character))
                            } label: {
                                CharacterRow(character: character)
                            }
                            .buttonStyle(.plain)
                            .onAppear {
                                        store.send(.scrolledToIndex(index))
                            }
                        }
                    }
                case .empty:
                    ContentUnavailableView(
                        "Characters not found",
                        systemImage: "person.slash",
                        description: Text("Try a different search.")
                    )
                case .failed(let message):
                    ContentUnavailableView(
                        "Something went wrong",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message)
                    )
                }
            }
            .navigationTitle("Characters")
            .searchable(text: $store.searchText)
            .task {
                store.send(.onAppear)
            }
        }
        destination: { store in
            switch store.case {
            case let .characterDetail(store):
                CharacterDetailsView(store: store)
            }
        }
    }
}

struct CharacterRow: View {
    let character: Models.Character

    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: character.imageURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                Text(character.name)
                    .font(.headline)

                Text(character.species)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    Circle()
                        .fill(character.status.color)
                        .frame(width: 10, height: 10)

                    Text(character.status.rawValue)
                        .font(.caption)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

