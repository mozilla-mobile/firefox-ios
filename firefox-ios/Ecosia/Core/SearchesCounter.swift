// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public final class SearchesCounter: StatePublisher {
    public var subscriptions = [Subscription<Int>]()
    public var state: Int? {
        return User.shared.searchCount
    }

    public init() {
        NotificationCenter.default.addObserver(self, selector: #selector(searchesCounterChanged), name: .searchesCounterChanged, object: nil)
    }

    @objc private func searchesCounterChanged() {
        send(state!)
    }
}
