// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Common

/// Helper utility that aims to detect potential bugs in production which could result in tab loss.
final class TabErrorTelemetryHelper {
    static let shared = TabErrorTelemetryHelper()
    private let defaultsKey = "TabErrorTelemetryHelper_Data"
    private let telemetryWrapper: TelemetryWrapperProtocol
    private let defaults: UserDefaultsInterface
    private let windowManager: WindowManager

    private init(telemetryWrapper: TelemetryWrapperProtocol = TelemetryWrapper.shared,
                 windowManager: WindowManager = AppContainer.shared.resolve(),
                 defaults: UserDefaultsInterface = UserDefaults.standard) {
        self.telemetryWrapper = telemetryWrapper
        self.defaults = defaults
        self.windowManager = windowManager
    }

    // MARK: - Public API

    /// Records the window's tab count upon the app being backgrounded.
    /// This count is then checked again upon foregrounding in an attempt to
    /// identify potential tab-loss errors.
    func recordTabCountForBackgroundedScene(_ window: WindowUUID) {
        ensureMainThread { self.recordTabCount(window) }
    }

    /// Validates the tab count when the app is foregrounded to ensure the
    /// count is consistent with the count upon backgrounding.
    func validateTabCountForForegroundedScene(_ window: WindowUUID) {
        ensureMainThread { self.validateTabCount(window) }
    }

    // MARK: - Internal Utility

    private func recordTabCount(_ window: WindowUUID) {
        guard self.tabManagerAvailable(for: window) else { return }
        var tabCounts = defaults.object(forKey: defaultsKey) as? [String: Int] ?? [String: Int]()
        let tabCount = getTabCount(window: window)
        tabCounts[window.uuidString] = tabCount
        defaults.set(tabCounts, forKey: defaultsKey)
    }

    private func validateTabCount(_ window: WindowUUID) {
        guard tabManagerAvailable(for: window) else { return }
        guard let tabCounts = defaults.object(forKey: defaultsKey) as? [String: Int],
              let expectedTabCount = tabCounts[window.uuidString] else { return }
        let currentTabCount = getTabCount(window: window)

        if expectedTabCount > 1 && (expectedTabCount - currentTabCount) > 1 {
            // Potential tab loss bug detected. Log a MetricKit error.
            sendTelemetryTabLossDetectedEvent()
        }

        // After validating the tab count, we make sure to remove the count
        // in preferences until the next time that the app is backgrounded.
        // This is to prevent false-positives that can occur if a stale count
        // is still in preferences and the app crashes. If the user removed
        // any tabs during this time, it means the next launch there will be
        // fewer tabs than recorded and we'll send the event erroneously.
        invalidateTabCount(for: window)
    }

    private func invalidateTabCount(for window: WindowUUID) {
        guard var tabCounts = defaults.object(forKey: defaultsKey) as? [String: Int] else { return }
        tabCounts.removeValue(forKey: window.uuidString)
        defaults.set(tabCounts, forKey: defaultsKey)
    }

    /// It's possible for this telemetry helper to be called during onboarding flow before
    /// any tab managers have been configured.
    private func tabManagerAvailable(for uuid: WindowUUID) -> Bool {
        guard let info = windowManager.windows[uuid],
              info.tabManager != nil else { return false }
        return true
    }

    private func getTabCount(window: WindowUUID) -> Int {
        assert(tabManagerAvailable(for: window), "getTabCount() should not be called prior to TabManager config.")
        return windowManager.tabManager(for: window).normalTabs.count
    }

    private func sendTelemetryTabLossDetectedEvent() {
        telemetryWrapper.recordEvent(category: .information,
                                     method: .error,
                                     object: .app,
                                     value: .tabLossDetected)
    }
}
