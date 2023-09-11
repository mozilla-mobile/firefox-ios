// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import UIKit

@testable import Client

class FakeReduxViewController: UIViewController, StoreSubscriber {
    typealias SubscriberStateType = FakeReduxState
    override func viewDidLoad() {
        super.viewDidLoad()
        store.dispatch(ActiveScreensStateAction.showScreen(.integrationTest))
        store.subscribe(self, transform: {
            $0.select(FakeReduxState.init)
        })
    }

    func newState(state: FakeReduxState) {
        print("YRD newState \(state)")
    }
}
