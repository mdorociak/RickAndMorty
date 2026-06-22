import ComposableArchitecture

public extension Shared<Set<Int>> {
    func toggle(_ id: Int) {
        withLock { ids in
            if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
        }
    }
}
