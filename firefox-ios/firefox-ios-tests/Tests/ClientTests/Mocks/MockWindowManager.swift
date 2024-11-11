// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Storage
import Common
@testable import Client

final class MockWindowManager: WindowManager {
    private let wrappedManager: WindowManagerImplementation

    var closePrivateTabsMultiActionCalled = 0

    init(wrappedManager: WindowManagerImplementation) {
        self.wrappedManager = wrappedManager
    }

    // MARK: - WindowManager Protocol

    var windows: [WindowUUID: AppWindowInfo] {
        wrappedManager.windows
    }

    func newBrowserWindowConfigured(_ windowInfo: AppWindowInfo, uuid: WindowUUID) {
        wrappedManager.newBrowserWindowConfigured(windowInfo, uuid: uuid)
    }

    func tabManager(for windowUUID: WindowUUID) -> TabManager {
        wrappedManager.tabManager(for: windowUUID)
    }

    func allWindowTabManagers() -> [TabManager] {
        wrappedManager.allWindowTabManagers()
    }

    func allWindowUUIDs(includingReserved: Bool) -> [WindowUUID] {
        wrappedManager.allWindowUUIDs(includingReserved: includingReserved)
    }

    func windowWillClose(uuid: WindowUUID) {
        wrappedManager.windowWillClose(uuid: uuid)
    }

    func reserveNextAvailableWindowUUID(isIpad: Bool) -> ReservedWindowUUID {
        wrappedManager.reserveNextAvailableWindowUUID(isIpad: isIpad)
    }

    func postWindowEvent(event: WindowEvent, windowUUID: WindowUUID) {
        wrappedManager.postWindowEvent(event: event, windowUUID: windowUUID)
    }

    func performMultiWindowAction(_ action: MultiWindowAction) {
        switch action {
        case .closeAllPrivateTabs:
            closePrivateTabsMultiActionCalled += 1
        default:
            break
        }
        wrappedManager.performMultiWindowAction(action)
    }

    func window(for tab: TabUUID) -> WindowUUID? {
        wrappedManager.window(for: tab)
    }
}
