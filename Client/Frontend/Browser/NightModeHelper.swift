/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Shared

struct NightModePrefsKey {
    static let NightModeButtonIsInMenu = PrefsKeys.KeyNightModeButtonIsInMenu
    static let NightModeStatus = PrefsKeys.KeyNightModeStatus
}

class NightModeHelper: TabHelper {

    fileprivate weak var tab: Tab?

    static var systemBrightness = UIScreen.main.brightness

    required init(tab: Tab) {
        self.tab = tab
        if let path = Bundle.main.path(forResource: "NightModeHelper", ofType: "js"), let source = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String {
            let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: true)
            tab.webView!.configuration.userContentController.addUserScript(userScript)
        }
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

    static func setNightModeBrightness(_ prefs: Prefs, enabled: Bool) {
        let nightModeBrightness: CGFloat
        if enabled {
            systemBrightness = CGFloat(UIScreen.main.brightness)
            nightModeBrightness = min(0.1, CGFloat(UIScreen.main.brightness))
        } else {
            nightModeBrightness = systemBrightness
        }
        UIView.animate(withDuration: 1.0, animations: {
            UIScreen.main.brightness = nightModeBrightness
        })
    }

    static func restoreNightModeBrightness(_ prefs: Prefs, toForeground: Bool) {
        let isNightMode = NightModeAccessors.isNightMode(prefs)
        if isNightMode {
            NightModeHelper.setNightModeBrightness(prefs, enabled: toForeground)
        } else {
            systemBrightness = UIScreen.main.brightness
        }
    }

    static func toggle(_ prefs: Prefs, tabManager: TabManager) {
        let isActive = prefs.boolForKey(NightModePrefsKey.NightModeStatus) ?? false
        setNightMode(prefs, tabManager: tabManager, enabled: !isActive)
    }
    
    static func setNightMode(_ prefs: Prefs, tabManager: TabManager, enabled: Bool) {
        prefs.setBool(enabled, forKey: NightModePrefsKey.NightModeStatus)
        for tab in tabManager.tabs {
            tab.setNightMode(enabled)
        }
        NightModeHelper.setNightModeBrightness(prefs, enabled: enabled)
    }

    static func isActivated(_ prefs: Prefs) -> Bool {
        return prefs.boolForKey(NightModePrefsKey.NightModeStatus) ?? false
    }
}

class NightModeAccessors {
    static func isNightMode(_ prefs: Prefs) -> Bool {
        return prefs.boolForKey(NightModePrefsKey.NightModeStatus) ?? false
    }
}
