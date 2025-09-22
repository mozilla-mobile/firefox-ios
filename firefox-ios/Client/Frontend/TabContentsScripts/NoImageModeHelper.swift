// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import Shared
import Common

struct NoImageModePrefsKey {
    static let NoImageModeStatus = PrefsKeys.KeyNoImageModeStatus
}

class NoImageModeHelper: TabContentScript {
    fileprivate weak var tab: Tab?

    required init(tab: Tab) {
        self.tab = tab
    }

    static func name() -> String {
        return "NoImageMode"
    }

    func scriptMessageHandlerNames() -> [String]? {
        return ["NoImageMode"]
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceiveScriptMessage message: WKScriptMessage
    ) {
        // Do nothing.
    }

    static func isActivated(_ prefs: Prefs) -> Bool {
        return prefs.boolForKey(NoImageModePrefsKey.NoImageModeStatus) ?? false
    }

    @MainActor
    static func toggle(isEnabled: Bool, profile: Profile) {
        profile.prefs.setBool(isEnabled, forKey: NoImageModePrefsKey.NoImageModeStatus)

        // We need to ensure we update tabs across all open iPad windows since the
        // No Image Mode is effectively a global setting (stored on the user profile)
        let windowManager: WindowManager = AppContainer.shared.resolve()
        let tabManagers = windowManager.allWindowTabManagers()
        tabManagers.forEach({ $0.tabs.forEach { $0.noImageMode = isEnabled } })

        if isEnabled {
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .blockImagesEnabled)
        } else {
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .blockImagesDisabled)
        }
    }
}
