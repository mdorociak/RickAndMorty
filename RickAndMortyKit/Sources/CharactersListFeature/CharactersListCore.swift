
import ComposableArchitecture
import SwiftUI
import Models
import SharedUI
import Networking
import CharacterDetailFeature
import EpisodeDetailFeature

@Reducer
public enum Path {
    case characterDetail(CharacterDetail)
    case episodeDetail(EpisodeDetail)
}

@Reducer
public struct CharactersList: Sendable {
    @ObservableState
    public struct State: Equatable {
        var characters: IdentifiedArrayOf<Character> = []
        public var searchText = ""
        var path = StackState<Path.State>()
        var isLoadingNextPage = false
        var loadingState: LoadingState = .idle
        
        var currentPage = 1
        var hasMorePages = false
        
        public init() {}
    }
    
    public enum Action: BindableAction {
        case onAppear
        case scrolledToIndex(Int)
        case binding(BindingAction<State>)
        case charactersResponse(Result<CharactersPage, Error>)
        case nextPageResponse(Result<CharactersPage, Error>)
        
        case path(StackActionOf<Path>)
        case characterTapped(Character)
    }
    
    private enum CancelID { case search, nextPage }
    
    @Dependency(\.apiClient) var apiClient
    @Dependency(\.continuousClock) var clock
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.loadingState == .idle else {
                    return .none
                }
                
                state.loadingState = .loading
                
                return .run { send in
                    await send(
                        .charactersResponse(
                            Result {
                                try await apiClient.characters(page: 1, name: nil)
                            }
                        )
                    )
                }
            case let .scrolledToIndex(index):
                guard state.hasMorePages,
                      !state.isLoadingNextPage,
                      index >= state.characters.count - 5
                else {
                    return .none
                }
                state.isLoadingNextPage = true
                let page = state.currentPage + 1
                let query = state.searchText
                return .run { send in
                    await send(
                        .nextPageResponse(
                            Result {
                                try await apiClient.characters(page: page, name: query.isEmpty ? nil : query)
                            }
                        )
                    )
                }
                .cancellable(id: CancelID.nextPage)
            
            case .binding(\.searchText):
                state.isLoadingNextPage = false
                let query = state.searchText
                return .run { send in
                    try await clock.sleep(for: .milliseconds(300))
                    await send(
                        .charactersResponse(
                            Result { try await apiClient.characters(page: 1, name: query.isEmpty ? nil : query) }
                        )
                    )
                }
                .cancellable(id: CancelID.search, cancelInFlight: true)
                .merge(with: .cancel(id: CancelID.nextPage))
            
            case .binding:
                return .none
                
            case let .characterTapped(character):
                state.path.append(.characterDetail(CharacterDetail.State(character: character)))
                return .none
                
            case let .charactersResponse(.success(page)):
                state.characters = IdentifiedArrayOf(uniqueElements: page.results)
                state.currentPage = 1
                state.hasMorePages = page.info.next != nil
                
                if page.results.isEmpty {
                    state.loadingState = .empty
                } else {
                    state.loadingState = .loaded
                }
                return .none
            
            case let .charactersResponse(.failure(error)):
                state.loadingState = .failed(error.localizedDescription)
                return .none
            
            case let .nextPageResponse(.success(page)):
                state.characters.append(contentsOf: page.results)
                state.currentPage += 1
                state.hasMorePages = page.info.next != nil
                state.isLoadingNextPage = false
                return .none
            
            case .nextPageResponse(.failure):
                state.isLoadingNextPage = false
                return .none
            
            case let .path(.element(id: _, action: .characterDetail(.delegate(.openEpisode(episode))))):
                state.path.append(.episodeDetail(EpisodeDetail.State(episode: episode)))
                return .none
                
            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

extension Path.State: Equatable {}
