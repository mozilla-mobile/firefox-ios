// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import WebKit
import Shared
import Common

struct NightModePrefsKey {
    static let NightModeButtonIsInMenu = PrefsKeys.KeyNightModeButtonIsInMenu
    static let NightModeStatus = PrefsKeys.KeyNightModeStatus
    static let NightModeEnabledDarkTheme = PrefsKeys.KeyNightModeEnabledDarkTheme
}

class NightModeHelper: TabContentScript {
    fileprivate weak var tab: Tab?

    required init(tab: Tab) {
        self.tab = tab
    }

    static func name() -> String {
        return "NightMode"
    }

    func scriptMessageHandlerName() -> String? {
        return "NightMode"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        // Do nothing.
    }

    static func toggle(_ userDefaults: UserDefaultsInterface = UserDefaults.standard,
                       tabManager: TabManager) {
        let isActive = userDefaults.bool(forKey: NightModePrefsKey.NightModeStatus) ?? false
        setNightMode(userDefaults, tabManager: tabManager, enabled: !isActive)
    }

    static func setNightMode(_ userDefaults: UserDefaultsInterface = UserDefaults.standard,
                             tabManager: TabManager,
                             enabled: Bool) {
        userDefaults.set(enabled, forKey: NightModePrefsKey.NightModeStatus)
        for tab in tabManager.tabs {
            tab.nightMode = enabled
            tab.webView?.scrollView.indicatorStyle = enabled ? .white : .default
        }
    }

    static func setEnabledDarkTheme(_ userDefaults: UserDefaultsInterface = UserDefaults.standard,
                                    darkTheme enabled: Bool) {
        userDefaults.set(enabled, forKey: NightModePrefsKey.NightModeEnabledDarkTheme)
    }

    static func hasEnabledDarkTheme(_ userDefaults: UserDefaultsInterface = UserDefaults.standard) -> Bool {
        return userDefaults.bool(forKey: NightModePrefsKey.NightModeEnabledDarkTheme) ?? false
    }

    static func isActivated(_ userDefaults: UserDefaultsInterface = UserDefaults.standard) -> Bool {
        return userDefaults.bool(forKey: NightModePrefsKey.NightModeStatus) ?? false
    }
}
