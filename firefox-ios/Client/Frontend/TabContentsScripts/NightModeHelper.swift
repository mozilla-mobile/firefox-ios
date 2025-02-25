// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import Shared
import Common
import Glean

class NightModeHelper: TabContentScript, FeatureFlaggable {
    private weak var tab: Tab?

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

    required init(tab: Tab) {
        self.tab = tab
    }

    static func jsCallbackBuilder(_ enabled: Bool) -> String {
        let isDarkReader = LegacyFeatureFlagsManager.shared.isFeatureEnabled(.darkReader, checking: .buildOnly)
        return "window.__firefox__.NightMode.setEnabled(\(enabled), \(isDarkReader))"
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceiveScriptMessage message: WKScriptMessage
    ) {
        guard let webView = message.frameInfo.webView else { return }

        NightModeHelper.isPageInDarkMode(webView: webView) { isInDarkPage in
            let enableComputedDarkMode = !isInDarkPage && NightModeHelper.isActivated()
            webView.evaluateJavascriptInCustomContentWorld(
                NightModeHelper.jsCallbackBuilder(enableComputedDarkMode),
                in: .world(name: NightModeHelper.name())
            )
        }
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

    static func isPageInDarkMode(webView: WKWebView?, completion: @escaping (Bool) -> Void) {
        let timerId = GleanMetrics.DarkReader.websiteDarkThemeDetection.start()
        takePageSnapshot(for: webView, at: 0.6, width: 300, height: 400) { color in
            let isPageDark = color?.isDark ?? false
            GleanMetrics.DarkReader.websiteDarkThemeDetection.stopAndAccumulate(timerId)
            completion(isPageDark)
        }
    }

    private static func takePageSnapshot(
        for webView: WKWebView?,
        at verticalOffset: CGFloat,
        width: CGFloat,
        height: CGFloat,
        completion: @escaping (UIColor?) -> Void
    ) {
        guard let webView = webView else { return }

        // Ensure width does not exceed the webView’s frame width
        let snapshotWidth = min(width, webView.frame.width)
        // Center horizontally
        let xPosition = (webView.frame.width - snapshotWidth) / 2

        let contentHeight = webView.scrollView.contentSize.height
        let snapshotHeight = min(height, contentHeight)

        var yPosition = contentHeight * verticalOffset
        // Shift up if the snapshot overflows the page
        if yPosition + snapshotHeight > contentHeight {
            yPosition = contentHeight - snapshotHeight
        }

        let config = WKSnapshotConfiguration()
        config.rect = CGRect(x: xPosition, y: yPosition, width: snapshotWidth, height: snapshotHeight)

        webView.takeSnapshot(with: config) { (image: UIImage?, _) in
            completion(image?.averageColor())
        }
    }
}
