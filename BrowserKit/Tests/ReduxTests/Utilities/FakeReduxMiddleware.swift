// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Redux
class FakeReduxMiddleware {
    lazy var fakeProvider: Middleware<FakeReduxState> = { state, action in
        switch action {
        case FakeReduxAction.requestInitialValue:
            let initialValue = self.generateInitialValue()
            DispatchQueue.main.async {
                store.dispatch(FakeReduxAction.initialValueLoaded(initialValue))
            }
        case FakeReduxAction.increaseCounter:
            let existingValue = state.counter
            let newValue = self.increaseCounter(currentValue: existingValue)
            DispatchQueue.main.async {
                store.dispatch(FakeReduxAction.counterIncreased(newValue))
            }
        case FakeReduxAction.decreaseCounter:
            let existingValue = state.counter
            let newValue = self.decreaseCounter(currentValue: existingValue)
            DispatchQueue.main.async {
                store.dispatch(FakeReduxAction.counterDecreased(newValue))
            }
        default:
           break
        }
    }

    private func increaseCounter(currentValue: Int) -> Int {
        return currentValue + 1
    }

    private func decreaseCounter(currentValue: Int) -> Int {
        return currentValue - 1
    }

    private func generateInitialValue() -> Int {
        return Int.random(in: 1...9)
    }
}
