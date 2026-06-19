import SwiftUI
import ComposableArchitecture

@Reducer
public struct RootFeature {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        public init() {}
    }
    public enum Action {}
    public var body: some ReducerOf<Self> {
        EmptyReducer()
    }
}
public struct RootView: View {
    @Bindable var store: StoreOf<RootFeature>
    
    public init() {
        self.store = Store(initialState: RootFeature.State()) {
            RootFeature()
        }
    }
    
    public init(store: StoreOf<RootFeature>) {
        self.store = store
    }
    public var body: some View {
        Text("View")
    }
}
#Preview {
    RootView(store: Store(initialState: RootFeature.State()) {
        RootFeature()
    })
}
