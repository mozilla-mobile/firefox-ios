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

    private weak var tab: Tab?

    required init(tab: Tab) {
        self.tab = tab
        if let path = NSBundle.mainBundle().pathForResource("NightModeHelper", ofType: "js"), source = try? NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String {
            let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentStart, forMainFrameOnly: true)
            tab.webView!.configuration.userContentController.addUserScript(userScript)
        }
    }

    static func name() -> String {
        return "NightMode"
    }

    func scriptMessageHandlerName() -> String? {
        return "NightMode"
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        // Do nothing.
    }

    static func setNightModeBrightness(prefs: Prefs, enabled: Bool) {
        let nightModeBrightness: CGFloat = 0.2
        if (enabled) {
            if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                appDelegate.systemBrightness = CGFloat(UIScreen.mainScreen().brightness)
            }
            UIScreen.mainScreen().brightness = nightModeBrightness
        } else {
            if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                UIScreen.mainScreen().brightness = appDelegate.systemBrightness
            }
        }
    }

    static func restoreNightModeBrightness(prefs: Prefs, toForeground: Bool) {
        let isNightMode = NightModeAccessors.isNightMode(prefs)
        if isNightMode {
            NightModeHelper.setNightModeBrightness(prefs, enabled: toForeground)
        } else {
            if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                appDelegate.systemBrightness = UIScreen.mainScreen().brightness
            }
        }
    }
    
    static func setNightMode(prefs: Prefs, tabManager: TabManager, enabled: Bool) {
        prefs.setBool(enabled, forKey: PrefsKeys.KeyNightModeStatus)
        for tab in tabManager.tabs {
            tab.setNightMode(enabled)
        }
        NightModeHelper.setNightModeBrightness(prefs, enabled: enabled)
    }
}

class NightModeAccessors {
    static func isNightMode(prefs: Prefs) -> Bool {
        return prefs.boolForKey(NightModePrefsKey.NightModeStatus) ?? false
    }

    static func isNightModeAvailable(state: AppState) -> Bool {
        return state.prefs.boolForKey(NightModePrefsKey.NightModeButtonIsInMenu) ?? AppConstants.MOZ_NIGHT_MODE
    }

    static func isNightModeActivated(state: AppState) -> Bool {
        return state.prefs.boolForKey(NightModePrefsKey.NightModeStatus) ?? false
    }
}
