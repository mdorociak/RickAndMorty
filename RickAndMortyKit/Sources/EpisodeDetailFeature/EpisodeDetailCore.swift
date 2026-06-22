
import ComposableArchitecture
import Models
import SharedUI
import Networking

@Reducer
public struct EpisodeDetail: Sendable {
    @ObservableState
    public struct State: Equatable {
        let episode: Episode
        var characters: [Character] = []
        var charactersState: LoadingState = .idle
        
        public init(episode: Episode) {
            self.episode = episode
        }
    }
    
    public enum Action {
        case onAppear
        case charactersResponse(Result<[Character], Error>)
    }
    
    @Dependency(\.apiClient) var apiClient
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.charactersState == .idle else {
                    return .none
                }
                state.charactersState = .loading
                let ids = state.episode.characterIDs
                return .run { send in
                    await send(
                        .charactersResponse(
                            Result {
                                try await apiClient.charactersByIDs(ids: ids)
                            }
                        )
                    )
                }
            case let .charactersResponse(.success(characters)):
                state.characters = characters
                state.charactersState = characters.isEmpty ? .empty : .loaded
                return .none
            case let .charactersResponse(.failure(error)):
                state.charactersState = .failed(error.localizedDescription)
                return .none
            }
        }
    }
}
