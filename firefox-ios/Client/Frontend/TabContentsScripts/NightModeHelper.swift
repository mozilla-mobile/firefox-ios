// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import Shared
import Common

class NightModeHelper: TabContentScript, FeatureFlaggable {
    private enum NightModeKeys {
        static let Status = "profile.NightModeStatus"
        static let DarkThemeEnabled = "NightModeEnabledDarkTheme"
    }

    static func name() -> String {
        return "NightMode"
    }

    func scriptMessageHandlerNames() -> [String]? {
        return ["NightMode"]
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceiveScriptMessage message: WKScriptMessage
    ) {
        guard let webView = message.frameInfo.webView else { return }
        let jsCallback = "window.__firefox__.NightMode.setEnabled(\(NightModeHelper.isActivated()))"
        webView.evaluateJavascriptInDefaultContentWorld(jsCallback)
    }

    static func toggle(
        _ userDefaults: UserDefaultsInterface = UserDefaults.standard
    ) {
        let isActive = userDefaults.bool(forKey: NightModeKeys.Status)
        setNightMode(userDefaults, enabled: !isActive)
    }

    static func setNightMode(
        _ userDefaults: UserDefaultsInterface = UserDefaults.standard,
        enabled: Bool
    ) {
        userDefaults.set(enabled, forKey: NightModeKeys.Status)
        let windowManager: WindowManager = AppContainer.shared.resolve()
        for tabManager in windowManager.allWindowTabManagers() {
            for tab in tabManager.tabs {
                tab.nightMode = enabled
                tab.webView?.scrollView.indicatorStyle = enabled ? .white : .default
            }
        }
    }

    static func isActivated(_ userDefaults: UserDefaultsInterface = UserDefaults.standard) -> Bool {
        return userDefaults.bool(forKey: NightModeKeys.Status)
    }

    // MARK: - Temporary functions
    // These functions are only here to help with the night mode experiment
    // and will be removed once a decision from that experiment is reached.
    // TODO: https://mozilla-hub.atlassian.net/browse/FXIOS-8475
    // Reminder: Any future refactors for 8475 need to work with multi-window.
    static func turnOff(
        _ userDefaults: UserDefaultsInterface = UserDefaults.standard
    ) {
        guard isActivated() else { return }
        setNightMode(userDefaults, enabled: false)
    }

    static func cleanNightModeDefaults(
        _ userDefaults: UserDefaultsInterface = UserDefaults.standard
    ) {
        userDefaults.removeObject(forKey: NightModeKeys.DarkThemeEnabled)
    }
}
