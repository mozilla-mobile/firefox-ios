/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

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
        if let path = Bundle.main.path(forResource: "NoImageModeHelper", ofType: "js"), let source = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String {
            let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: true)
            tab.webView!.configuration.userContentController.addUserScript(userScript)
        }
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

    static func toggle(profile: Profile, tabManager: TabManager) {
        if #available(iOS 11, *) {
            let enabled = !isActivated(profile.prefs)
            profile.prefs.setBool(enabled, forKey: PrefsKeys.KeyNoImageModeStatus)
            tabManager.tabs.forEach { $0.noImageMode = enabled }
        }
    }
}
