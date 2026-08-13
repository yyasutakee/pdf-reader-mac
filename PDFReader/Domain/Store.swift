import SwiftUI
import Combine

/// A generic base class for a single source of truth state store.
class Store<State>: ObservableObject {
    /// The current state, read-only from the outside to enforce mutation through setState.
    private(set) var state: State

    /// Publishes the state AFTER every mutation, carrying the new value as its element.
    ///
    /// WHY: `objectWillChange` must fire BEFORE the mutation — that is SwiftUI's contract, and a View re-reads
    /// `state` on a later run loop turn, so it sees the new value anyway. A plain Combine subscriber has no such
    /// second turn: subscribing to `objectWillChange` and then reading `state` in the handler yields the PREVIOUS
    /// value. Carrying the new state as the element removes that trap entirely — the subscriber is handed the
    /// value and never needs to read `state` back off the store.
    let didChange: PassthroughSubject<State, Never> = PassthroughSubject<State, Never>()

    init(initialState: State) {
        self.state = initialState
    }

    /// The ONLY way to modify state.
    // WHY: manual objectWillChange.send() avoids the compiler crash that @Published triggers in generic
    // ObservableObject subclasses; the inout closure is the single funnel every mutation passes through.
    func setState(_ mutation: (inout State) -> Void) {
        objectWillChange.send()
        mutation(&state)
        didChange.send(state)
    }

    deinit {}
}
