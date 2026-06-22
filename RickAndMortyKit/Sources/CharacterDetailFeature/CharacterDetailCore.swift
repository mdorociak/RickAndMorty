
import ComposableArchitecture
import Models
import SharedUI
import Networking

@Reducer
public struct CharacterDetail: Sendable {
    @ObservableState
    public struct State: Equatable {
        public let character: Character
        @Shared(.favoriteIDs) var favoriteIDs: Set<Int>
        
        var episodes: [Episode] = []
        var episodesState: LoadingState = .idle
        
        public init(character: Character) {
            self.character = character
        }
    }
    
    public enum Action {
        case onAppear
        case favoriteToggled
        case episodesResponse(Result<[Episode], Error>)
        case episodeTapped(Episode)
        case delegate(Delegate)
        
        @CasePathable
        public enum Delegate {
            case openEpisode(Episode)
        }
    }
    
    @Dependency(\.apiClient) var apiClient
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            
            case .onAppear:
                guard state.episodesState == .idle else {
                    return .none
                }
                
                state.episodesState = .loading
                
                let ids = state.character.episodeIDs
                
                return .run { send in
                        await send(
                            .episodesResponse(
                                Result{
                                    try await apiClient.episodes(ids: ids)
                                }
                            )
                        )
                    }
            case .favoriteToggled:
                let id = state.character.id
                state.$favoriteIDs.toggle(id)
                return .none
            
            case let .episodesResponse(.success(episodes)):
                state.episodes = episodes
                state.episodesState = episodes.isEmpty ? .empty : .loaded
                return .none
            
            case let .episodesResponse(.failure(error)):
                state.episodesState = .failed(error.localizedDescription)
                return .none
            
            case let .episodeTapped(episode):
                return .send(
                    .delegate(.openEpisode(episode))
                )
            case .delegate:
                return .none
            }
        }
    }
}
