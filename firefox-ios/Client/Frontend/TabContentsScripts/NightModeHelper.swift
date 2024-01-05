// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import Shared
import Common

class NightModeHelper: TabContentScript {
    private enum NightModeKeys {
        static let Status = "profile.NightModeStatus"
        static let DarkThemeEnabled = "NightModeEnabledDarkTheme"
    }

    fileprivate weak var tab: Tab?

    required init(tab: Tab) {
        self.tab = tab
    }

    static func name() -> String {
        return "NightMode"
    }

    func scriptMessageHandlerNames() -> [String]? {
        return ["NightMode"]
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        // Do nothing.
    }

    static func toggle(_ userDefaults: UserDefaultsInterface = UserDefaults.standard,
                       tabManager: TabManager) {
        let isActive = userDefaults.bool(forKey: NightModeKeys.Status)
        setNightMode(userDefaults, tabManager: tabManager, enabled: !isActive)
    }

    static func setNightMode(_ userDefaults: UserDefaultsInterface = UserDefaults.standard,
                             tabManager: TabManager,
                             enabled: Bool) {
        userDefaults.set(enabled, forKey: NightModeKeys.Status)
        for tab in tabManager.tabs {
            tab.nightMode = enabled
            tab.webView?.scrollView.indicatorStyle = enabled ? .white : .default
        }
    }

    static func setEnabledDarkTheme(_ userDefaults: UserDefaultsInterface = UserDefaults.standard,
                                    darkTheme enabled: Bool) {
        userDefaults.set(enabled, forKey: NightModeKeys.DarkThemeEnabled)
    }

    static func hasEnabledDarkTheme(_ userDefaults: UserDefaultsInterface = UserDefaults.standard) -> Bool {
        return userDefaults.bool(forKey: NightModeKeys.DarkThemeEnabled)
    }

    static func isActivated(_ userDefaults: UserDefaultsInterface = UserDefaults.standard) -> Bool {
        return userDefaults.bool(forKey: NightModeKeys.Status)
    }
}
