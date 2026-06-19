
import ComposableArchitecture
import SwiftUI
import Models
import Networking

@Reducer
public struct CharactersList: Sendable {
    @ObservableState
    public struct State: Equatable {
        var characters: [Character] = []
        
        var loadingState: LoadingState = .idle
        
        var currentPage = 1
        var totalPages = 1
        
        public init() {}
    }
    
    public enum Action {
        case onAppear
        case charactersResponse(Result<CharactersPage, Error>)
    }
    
    @Dependency(\.apiClient)
    var apiClient
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
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
            case let .charactersResponse(.success(page)):
                state.characters = page.results
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
