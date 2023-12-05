// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

@testable import Redux
class FakeReduxViewController: UIViewController, StoreSubscriber {
    typealias SubscriberStateType = FakeReduxState

    var label = UILabel(frame: .zero)
    var isInPrivateMode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeToRedux()
        view.addSubview(label)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unsubscribeFromRedux()
    }

    // MARK: - Redux

    func subscribeToRedux() {
        store.subscribe(self)
        store.dispatch(FakeReduxAction.requestInitialValue)
    }

    func unsubscribeFromRedux() {
        store.unsubscribe(self)
    }

    func newState(state: FakeReduxState) {
        label.text = "\(state.counter)"
        isInPrivateMode = state.isInPrivateMode
    }

    // MARK: - Helper functions

    func increaseCounter() {
        store.dispatch(FakeReduxAction.increaseCounter)
    }

    func decreaseCounter() {
        store.dispatch(FakeReduxAction.decreaseCounter)
    }

    func setPrivateMode(to value: Bool) {
        store.dispatch(FakeReduxAction.setPrivateModeTo(value))
    }
}
