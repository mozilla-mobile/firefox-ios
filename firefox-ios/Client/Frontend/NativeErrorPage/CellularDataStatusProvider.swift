// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import CoreTelephony

protocol CellularDataStatusProviding {
    var isCellularDataRestricted: Bool { get }
}

/// `CTCellularData.restrictedState` reports `.restrictedStateUnknown` until the system
/// resolves it asynchronously after the object is created, so this is kept as a
/// long-lived singleton (warmed up at app launch) and caches updates from
/// `cellularDataRestrictionDidUpdateNotifier` rather than doing a single synchronous read.
final class CTCellularDataStatusProvider: CellularDataStatusProviding, @unchecked Sendable {
    static let shared = CTCellularDataStatusProvider()

    private let cellularData = CTCellularData()
    private let lock = NSLock()
    private var cachedState: CTCellularDataRestrictedState

    private init() {
        cachedState = cellularData.restrictedState
        cellularData.cellularDataRestrictionDidUpdateNotifier = { [weak self] state in
            self?.updateCachedState(state)
        }
    }

    func updateCachedState(_ state: CTCellularDataRestrictedState) {
        lock.lock()
        cachedState = state
        lock.unlock()
    }

    var isCellularDataRestricted: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cachedState == .restricted
    }
}
