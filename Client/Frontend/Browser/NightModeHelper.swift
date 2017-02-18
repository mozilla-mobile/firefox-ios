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
        let nightModeBrightness: CGFloat = min(0.2, CGFloat(UIScreen.main.brightness))
        if enabled {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.systemBrightness = CGFloat(UIScreen.main.brightness)
            }
            UIScreen.main.brightness = nightModeBrightness
        } else {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                UIScreen.main.brightness = appDelegate.systemBrightness
            }
        }
    }

    static func restoreNightModeBrightness(_ prefs: Prefs, toForeground: Bool) {
        let isNightMode = NightModeAccessors.isNightMode(prefs)
        if isNightMode {
            NightModeHelper.setNightModeBrightness(prefs, enabled: toForeground)
        } else {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.systemBrightness = UIScreen.main.brightness
            }
        }
    }
    
    static func setNightMode(_ prefs: Prefs, tabManager: TabManager, enabled: Bool) {
        prefs.setBool(enabled, forKey: PrefsKeys.KeyNightModeStatus)
        for tab in tabManager.tabs {
            tab.setNightMode(enabled)
        }
        NightModeHelper.setNightModeBrightness(prefs, enabled: enabled)
    }
}

class NightModeAccessors {
    static func isNightMode(_ prefs: Prefs) -> Bool {
        return prefs.boolForKey(NightModePrefsKey.NightModeStatus) ?? false
    }

    static func isNightModeAvailable(_ state: AppState) -> Bool {
        return state.prefs.boolForKey(NightModePrefsKey.NightModeButtonIsInMenu) ?? AppConstants.MOZ_NIGHT_MODE
    }

    static func isNightModeActivated(_ state: AppState) -> Bool {
        return state.prefs.boolForKey(NightModePrefsKey.NightModeStatus) ?? false
    }
}
