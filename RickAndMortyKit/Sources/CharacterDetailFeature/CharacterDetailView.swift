
import ComposableArchitecture
import SwiftUI
import Models
import SharedUI

public struct CharacterDetailsView: View {
    @Bindable var store: StoreOf<CharacterDetail>

    public init(store: StoreOf<CharacterDetail>) {
        self.store = store
    }

    public var body: some View {
        List {
            Section {
                CharacterHeader(character: store.character)
                    .listRowInsets(EdgeInsets())
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
                            Button {
                                store.send(.episodeTapped(episode))
                            } label: {
                                EpisodeRow(episode: episode)
                            }
                            .buttonStyle(.plain)
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    store.send(.favoriteToggled)
                } label: {
                    Image(systemName: store.favoriteIDs.contains(store.character.id) ? "heart.fill" : "heart")
                        .foregroundStyle(store.favoriteIDs.contains(store.character.id) ? .red : .secondary)
                }
            }
        }
        .task {
            store.send(.onAppear)
        }
    }
}

struct CharacterHeader: View {
    let character: Character
    var body: some View {
        AsyncImage(url: character.imageURL) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            ProgressView()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .clipped()
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
