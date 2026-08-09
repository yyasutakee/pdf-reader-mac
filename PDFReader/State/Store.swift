import SwiftUI
import Combine

class Store<State>: ObservableObject {
    private(set) var state: State

    init(initialState: State) {
        self.state = initialState
    }

    func setState(_ mutation: (inout State) -> Void) {
        objectWillChange.send()
        mutation(&state)
    }
}
