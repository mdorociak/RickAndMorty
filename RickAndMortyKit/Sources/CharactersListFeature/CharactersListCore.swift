
import ComposableArchitecture
import SwiftUI
import Models
import Networking

@Reducer
public struct CharactersList: Sendable {
    @ObservableState
    public struct State: Equatable {
        var characters: IdentifiedArrayOf<Character> = []
        public var searchText = ""
        
        var isLoadingNextPage = false
        var loadingState: LoadingState = .idle
        
        var currentPage = 1
        var totalPages = 1
        
        public init() {}
    }
    
    public enum Action: BindableAction {
        case onAppear
        case reachedBottom
        case binding(BindingAction<State>)
        case charactersResponse(Result<CharactersPage, Error>)
        case nextPageResponse(Result<CharactersPage, Error>)
    }
    
    private enum CancelID { case search }
    
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
            case .reachedBottom:
                guard !state.isLoadingNextPage, state.currentPage < state.totalPages else {
                    return .none
                }
                state.isLoadingNextPage = true
                let targetPage = state.currentPage + 1
                let query = state.searchText
                return .run { send in
                    await send(
                        .nextPageResponse(
                            Result {
                                try await apiClient.characters(page: targetPage, name: query.isEmpty ? nil : query)
                            }
                        )
                    )
                }
            
            case .binding(\.searchText):
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
            
            case .binding:
                return .none
                
            case let .charactersResponse(.success(page)):
                state.characters = IdentifiedArrayOf(uniqueElements: page.results)
                state.currentPage = 1
                state.totalPages = page.info.pages
                
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
                
                state.isLoadingNextPage = false
                return .none
            
            case .nextPageResponse(.failure):
                state.isLoadingNextPage = false
                return .none
            }
        }
    }
}

enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case empty
    case failed(String)
}
