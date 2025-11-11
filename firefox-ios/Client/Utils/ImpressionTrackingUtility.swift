// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

final class ImpressionTrackingUtility {
    let impressionVisibilityThreshold: Double
    private var sent = Set<IndexPath>()
    private var pending = Set<IndexPath>()

    init(withCustomVisibilityThreshold threshold: Double = 0.5) {
        self.impressionVisibilityThreshold = threshold
    }

    func markPending(_ indexPath: IndexPath) {
        pending.insert(indexPath)
    }

    func flush(send: ([IndexPath]) -> Void) {
        let toSend = pending.subtracting(sent)
        guard !toSend.isEmpty else { return }
        sent.formUnion(toSend)
        pending.removeAll()
        send(Array(toSend))
    }

    func reset() {
        sent.removeAll()
        pending.removeAll()
    }
}
