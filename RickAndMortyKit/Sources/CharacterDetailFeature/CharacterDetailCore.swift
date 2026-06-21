
import ComposableArchitecture
import SwiftUI
import Models
import SharedUI
import Networking

@Reducer
public struct CharacterDetail: Sendable {
    @ObservableState
    public struct State: Equatable {
        public let character: Character
        
        var episodes: [Episode] = []
        var episodesState: LoadingState = .idle
        
        public init(character: Character) {
            self.character = character
        }
    }
    
    public enum Action {
        case onAppear
        case episodesResponse(Result<[Episode], Error>)
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
            case let .episodesResponse(.success(episodes)):
                state.episodes = episodes
                state.episodesState = episodes.isEmpty ? .empty : .loaded
                return .none
            
            case let .episodesResponse(.failure(error)):
                state.episodesState = .failed(error.localizedDescription)
                return .none
            }
        }
    }
}
