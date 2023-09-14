// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Redux
class FakeReduxMiddleware {
    var counter: Int = 0

    lazy var fakeProvider: Middleware<FakeReduxState> = { state, action in
        switch action {
        case FakeReduxAction.requestInitialValue:
            self.getInitialValue()
            DispatchQueue.main.async {
                store.dispatch(FakeReduxAction.initialValueLoaded(self.counter))
            }
        case FakeReduxAction.increaseCounter:
            self.increaseCounter()
            DispatchQueue.main.async {
                store.dispatch(FakeReduxAction.counterIncreased(self.counter))
            }
        case FakeReduxAction.decreaseCounter:
            self.decreaseCounter()
            DispatchQueue.main.async {
                store.dispatch(FakeReduxAction.counterDecreased(self.counter))
            }
        default:
           break
        }
    }

    private func increaseCounter() {
        counter += 1
    }

    private func decreaseCounter() {
        counter -= 1
    }

    private func getInitialValue() {
        counter = Int.random(in: Range(1...9))
    }
}
