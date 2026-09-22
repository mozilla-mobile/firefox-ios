// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import CoreTelephony
import Foundation

protocol CellularDataStateProvider {
    var isRestricted: Bool { get }
}

extension CellularDataStateProvider {
    func isRestrictedOfflineError(_ error: NSError) -> Bool {
        let offlineErrorCode = Int(CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue)
        return error.domain == NSURLErrorDomain && error.code == offlineErrorCode && isRestricted
    }
}

final class SystemCellularDataStateProvider: CellularDataStateProvider, @unchecked Sendable {
    static let shared = SystemCellularDataStateProvider()

    private let cellularData: CTCellularData
    private let stateLock = NSLock()
    private var restrictedState: CTCellularDataRestrictedState

    private init(cellularData: CTCellularData = CTCellularData()) {
        self.cellularData = cellularData
        self.restrictedState = cellularData.restrictedState
        cellularData.cellularDataRestrictionDidUpdateNotifier = { [weak self] state in
            self?.updateRestrictedState(state)
        }
    }

    var isRestricted: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return restrictedState == .restricted
    }

    private func updateRestrictedState(_ state: CTCellularDataRestrictedState) {
        stateLock.lock()
        restrictedState = state
        stateLock.unlock()
    }
}
