
import ComposableArchitecture
import SwiftUI
import Models

public struct CharacterDetailsView: View {
    @Bindable var store: StoreOf<CharacterDetail>

    public init(store: StoreOf<CharacterDetail>) {
        self.store = store
    }

    public var body: some View {
        List {
            Section {
                CharacterHeader(character: store.character)
            }
            
            Section("Info") {
                
                LabeledContent("Status") {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(store.character.status.color)
                            .frame(width: 10, height: 10)
                        Text(store.character.status.rawValue)
                    }
                }
                LabeledContent("Species", value: store.character.species)
                LabeledContent("Gender", value: store.character.gender.rawValue)
                LabeledContent("Origin", value: store.character.origin.name)
                LabeledContent("Location", value: store.character.location.name)
                            
            }
            
            Section("Episodes") {

                    switch store.episodesState {
                    case .idle, .loading:
                        ProgressView()

                    case .loaded:
                        ForEach(store.episodes) { episode in
                            EpisodeRow(episode: episode)
                        }

                    case .empty:
                        ContentUnavailableView(
                            "No episodes",
                            systemImage: "film"
                        )

                    case .failed(let message):
                        ContentUnavailableView(
                            "Couldn't load episodes",
                            systemImage: "exclamationmark.triangle",
                            description: Text(message)
                        )
                    }
                }
        }
        .navigationTitle(store.character.name)
        .task {
            store.send(.onAppear)
        }
    }
}

struct CharacterHeader: View {
    let character: Character
    var body: some View {
        VStack(spacing: 16) {
            AsyncImage(url: character.imageURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 180, height: 180)
            .clipShape(Circle())
        }
        .frame(maxWidth: .infinity)
    }
}

struct EpisodeRow: View {
    let episode: Episode

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(episode.name)
                .font(.headline)

            Text(episode.episodeCode)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(episode.airDate)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
    }
}
