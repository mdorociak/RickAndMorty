
import ComposableArchitecture
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
        var charactersByID: [Int: Character] = [:]
        
        
        var favoriteCharacters: IdentifiedArrayOf<Character> {
            IdentifiedArrayOf(
                uniqueElements: favoriteIDs
                    .compactMap { charactersByID[$0] }
                    .sorted { $0.name < $1.name }
            )
        }
        var otherCharacters: IdentifiedArrayOf<Character> {
            characters.filter { !favoriteIDs.contains($0.id) }
        }
       
        var path = StackState<Path.State>()
        var loadingState: LoadingState = .idle
        
        public var searchText = ""
        @Shared(.favoriteIDs) var favoriteIDs: Set<Int>
        
        var currentPage = 1
        var hasMorePages = false
        var isLoadingNextPage = false
        
        public init() {}
    }
    
    public enum Action: BindableAction {
        case onAppear
        case refresh
        case characterAppeared(Character.ID)
        case binding(BindingAction<State>)
        case charactersResponse(Result<CharactersPage, Error>)
        case nextPageResponse(Result<CharactersPage, Error>)
        
        case path(StackActionOf<Path>)
        case characterTapped(Character)
        case favoriteToggled(Character)
        case favoritesFetched(Result<[Character], Error>)
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
                guard state.loadingState == .idle else { return .none }
                state.loadingState = .loading

                let missingFavoriteIDs = state.favoriteIDs.filter { state.charactersByID[$0] == nil }

                return .merge(
                    .run { send in
                        await send(.charactersResponse(Result {
                            try await apiClient.characters(page: 1, name: nil)
                        }))
                    },
                    .run { send in
                        guard !missingFavoriteIDs.isEmpty else { return }
                        await send(.favoritesFetched(Result {
                            try await apiClient.charactersByIDs(ids: Array(missingFavoriteIDs))
                        }))
                    }
                )
            case .refresh:
                state.isLoadingNextPage = false
                let query = state.searchText
                return .run { send in
                    await send(
                        .charactersResponse(
                            Result {
                                try await apiClient.characters(page: 1, name: query.isEmpty ? nil : query)
                            }
                        )
                    )
                }
                .merge(with: .cancel(id: CancelID.nextPage))
                
            case let .characterAppeared(id):
                guard state.hasMorePages,
                      !state.isLoadingNextPage,
                      let index = state.characters.index(id: id),
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
            
            case let .favoriteToggled(character):
                state.$favoriteIDs.toggle(character.id)
                return .none
            
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
                for character in page.results {
                    state.charactersByID[character.id] = character
                }
                state.currentPage = 1
                state.hasMorePages = page.info.next != nil
                state.loadingState = page.results.isEmpty ? .empty : .loaded
                return .none

            
            case let .charactersResponse(.failure(error)):
                state.loadingState = .failed(error.localizedDescription)
                return .none
            
            case let .nextPageResponse(.success(page)):
                state.characters.append(contentsOf: page.results)
                for character in page.results {
                    state.charactersByID[character.id] = character
                }
                state.currentPage += 1
                state.hasMorePages = page.info.next != nil
                state.isLoadingNextPage = false
                return .none
            
            case .nextPageResponse(.failure):
                state.isLoadingNextPage = false
                return .none
            
            case let .favoritesFetched(.success(characters)):
                for character in characters {
                    state.charactersByID[character.id] = character
                }
                return .none

            case .favoritesFetched(.failure):
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
