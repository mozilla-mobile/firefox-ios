// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Common

final class TabErrorTelemetryHelper {
    static let shared = TabErrorTelemetryHelper()
    private let defaultsKey = "TabErrorTelemetryHelper_Data"
    private let telemetryWrapper: TelemetryWrapperProtocol

    private init(telemetryWrapper: TelemetryWrapperProtocol = TelemetryWrapper.shared) {
        self.telemetryWrapper = telemetryWrapper
    }

    /// Records the scene (windows) tab count for the purposes of sanity-checking for
    /// potential tab-loss related errors. Such bugs can significantly impact users, so
    /// we attempt to detect any issues which could indicate potential tab loss.
    func recordTabCountForBackgroundedScene(_ window: WindowUUID) {
        ensureMainThread {
            var tabCounts = UserDefaults.standard.object(forKey: self.defaultsKey) as? [String: Int] ?? [String: Int]()
            let tabCount = self.getTabCount(window: window)
            tabCounts[window.uuidString] = tabCount
            UserDefaults.standard.set(tabCounts, forKey: self.defaultsKey)
        }
    }

    /// Validates the tab count against the recorded tab count. If this has decreased
    /// without any obvious cause (e.g. Close All Tabs action) then it is suggestive of
    /// a potential bug impacting users, and a MetricKit event is logged.
    func validateTabCountForForegroundedScene(_ window: WindowUUID) {
        guard let tabCounts = UserDefaults.standard.object(forKey: self.defaultsKey) as? [String: Int],
              let expectedTabCount = tabCounts[window.uuidString] else { return }
        let currentTabCount = getTabCount(window: window)

        if expectedTabCount > 1 && (expectedTabCount - currentTabCount) > 1 {
            // Potential tab loss bug detected. Log a MetricKit error.
            sendTelemetryTabLossDetectedEvent()
        }
    }

    // MARK: - Internal Utility

    private func getTabCount(window: WindowUUID) -> Int {
        let windowManager: WindowManager = AppContainer.shared.resolve()
        return windowManager.tabManager(for: window).normalTabs.count
    }

    private func sendTelemetryTabLossDetectedEvent() {
        telemetryWrapper.recordEvent(category: .information,
                                     method: .error,
                                     object: .app,
                                     value: .tabLossDetected)
    }
}
