// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

@testable import Redux

let windowUUID = UUID(uuidString: "D9D9D9D9-D9D9-D9D9-D9D9-CD68A019860B")!

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

        let action = FakeReduxAction(windowUUID: windowUUID, actionType: FakeReduxActionType.requestInitialValue)
        store.dispatch(action)
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
        let action = FakeReduxAction(windowUUID: windowUUID, actionType: FakeReduxActionType.increaseCounter)
        store.dispatch(action)
    }

    func decreaseCounter() {
        let action = FakeReduxAction(windowUUID: windowUUID, actionType: FakeReduxActionType.decreaseCounter)
        store.dispatch(action)
    }

    func setPrivateMode(to value: Bool) {
        let action = FakeReduxAction(privateMode: value,
                                     windowUUID: windowUUID,
                                     actionType: FakeReduxActionType.setPrivateModeTo)
        store.dispatch(action)
    }
}
