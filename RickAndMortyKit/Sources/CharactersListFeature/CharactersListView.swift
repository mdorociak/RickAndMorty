
import ComposableArchitecture
import SwiftUI
import Models

@MainActor
public struct CharactersListView: View {
    @Bindable var store: StoreOf<CharactersList>
    
    public init(store: StoreOf<CharactersList>) {
        self.store = store
    }
    
    public var body: some View {
        NavigationStack {
            Group {
                switch store.loadingState {
                case .idle, .loading:
                    ProgressView("Loading characters")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .loaded:
                    List {
                        ForEach(Array(store.characters.enumerated()), id: \.element.id) { index, character in
                            CharacterRow(character: character)
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
                        .fill(statusColor)
                        .frame(width: 10, height: 10)

                    Text(character.status.rawValue)
                        .font(.caption)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch character.status {
        case .alive:
            return .green
        case .dead:
            return .red
        case .unknown:
            return .gray
        }
    }
}

