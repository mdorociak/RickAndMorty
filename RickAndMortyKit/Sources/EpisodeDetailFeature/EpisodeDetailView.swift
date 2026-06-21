
import ComposableArchitecture
import SwiftUI
import Models

public struct EpisodeDetailView: View {
    @Bindable var store: StoreOf<EpisodeDetail>

    public init(store: StoreOf<EpisodeDetail>) {
        self.store = store
    }

    public var body: some View {
        List {
            Section("Info") {
                LabeledContent("Aired", value: store.episode.airDate)
                LabeledContent("Episode", value: store.episode.episodeCode)
            }
            
            Section("Characters") {
                switch store.charactersState {
                case .idle, .loading:
                    ProgressView()
                case .loaded:
                    ForEach(store.characters) { character in
                        EpisodeCharacterRow(character: character)
                    }
                case .empty:
                    ContentUnavailableView("No characters", systemImage: "person.slash")
                case .failed(let message):
                    ContentUnavailableView("Couldn't load characters",
                                           systemImage: "exclamationmark.triangle",
                                           description: Text(message)
                    )
                }
            }
            
        }
        .navigationTitle(store.episode.name)
        .task {
            store.send(.onAppear)
        }
    }
}

struct EpisodeCharacterRow: View {
    let character: Character
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: character.imageURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(character.name)
                .font(.headline)
        }
    }
}

