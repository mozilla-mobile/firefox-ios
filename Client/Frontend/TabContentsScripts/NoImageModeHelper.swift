// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import WebKit
import Shared

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

    func scriptMessageHandlerName() -> String? {
        return "NoImageMode"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        // Do nothing.
    }

    static func isActivated(_ prefs: Prefs) -> Bool {
        return prefs.boolForKey(NoImageModePrefsKey.NoImageModeStatus) ?? false
    }

    static func toggle(isEnabled: Bool, profile: Profile, tabManager: TabManager) {
        profile.prefs.setBool(isEnabled, forKey: NoImageModePrefsKey.NoImageModeStatus)
        tabManager.tabs.forEach { $0.noImageMode = isEnabled }

        if isEnabled {
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .blockImagesEnabled)
        } else {
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .blockImagesDisabled)
        }
    }
}
