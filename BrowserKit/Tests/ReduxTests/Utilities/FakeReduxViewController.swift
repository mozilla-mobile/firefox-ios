// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

@testable import Redux
class FakeReduxViewController: UIViewController, StoreSubscriber {
    typealias SubscriberStateType = FakeReduxState

    var label = UILabel(frame: .zero)

    override func viewDidLoad() {
        super.viewDidLoad()
        store.subscribe(self)
        store.dispatch(FakeReduxAction.requestInitialValue)
        view.addSubview(label)
    }

    func newState(state: FakeReduxState) {
        label.text = "\(state.counter)"
    }

    func increaseCounter() {
        store.dispatch(FakeReduxAction.increaseCounter)
    }

    func decreaseCounter() {
        store.dispatch(FakeReduxAction.decreaseCounter)
    }
}
