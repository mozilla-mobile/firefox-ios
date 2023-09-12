// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

@testable import Redux
class FakeReduxViewController: UIViewController, StoreSubscriber {
    typealias SubscriberStateType = FakeReduxState

    var counter: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        store.subscribe(self)
    }

    func newState(state: FakeReduxState) {
        print("YRD newState \(state)")
        counter = state.counter
    }

    func increaseCounter() {
        store.dispatch(FakeReduxAction.increaseCounter(1))
    }

    func decreaseCounter() {
        store.dispatch(FakeReduxAction.increaseCounter(0))
    }
}
