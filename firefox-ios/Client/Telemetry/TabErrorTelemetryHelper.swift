// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// Helper utility that aims to detect potential bugs in production which could result in tab loss.
final class TabErrorTelemetryHelper {
    static let shared = TabErrorTelemetryHelper()
    private let telemetryWrapper: TelemetryWrapperProtocol
    private let defaults: UserDefaultsInterface
    private let windowManager: WindowManager
    private let logger: Logger

    private enum EntryPoint {
        case backgroundForeground
        case preserveRestore

        var logInfo: String {
            switch self {
            case .backgroundForeground:
                return "on foreground"
            case .preserveRestore:
                return "on tab restore"
            }
        }

        var defaultsKey: String {
            let foregroundDefaultsKey = "TabErrorTelemetryHelper_Data_BackgroundForegroundEvent"
            let restoreDefaultsKey = "TabErrorTelemetryHelper_Data_PreserveRestoreEvent"

            switch self {
            case .backgroundForeground:
                return foregroundDefaultsKey
            case .preserveRestore:
                return restoreDefaultsKey
            }
        }
    }

    private init(logger: Logger = DefaultLogger.shared,
                 telemetryWrapper: TelemetryWrapperProtocol = TelemetryWrapper.shared,
                 windowManager: WindowManager = AppContainer.shared.resolve(),
                 defaults: UserDefaultsInterface = UserDefaults.standard) {
        self.telemetryWrapper = telemetryWrapper
        self.defaults = defaults
        self.windowManager = windowManager
        self.logger = logger
    }

    // MARK: - Public API

    /// Records the window's tab count upon the app being backgrounded.
    /// This count is then checked again upon foregrounding in an attempt to
    /// identify potential tab-loss errors.
    func recordTabCountForBackgroundedScene(_ window: WindowUUID) {
        ensureMainThread { self.recordTabCount(window, entryPoint: .backgroundForeground) }
    }

    /// Validates the tab count when the app is foregrounded to ensure the
    /// count is consistent with the count upon backgrounding.
    func validateTabCountForForegroundedScene(_ window: WindowUUID) {
        ensureMainThread { self.validateTabCount(window, entryPoint: .backgroundForeground) }
    }

    @MainActor
    func recordTabCountAfterPreservingTabs(_ window: WindowUUID) async {
        recordTabCount(window, entryPoint: .preserveRestore)
    }

    @MainActor
    func validateTabCountAfterRestoringTabs(_ window: WindowUUID) async {
        validateTabCount(window, entryPoint: .preserveRestore)
    }

    // MARK: - Internal Utility

    private func recordTabCount(_ window: WindowUUID, entryPoint: EntryPoint) {
        guard self.tabManagerAvailable(for: window) else { return }
        var tabCounts = defaults.object(forKey: entryPoint.defaultsKey) as? [String: Int] ?? [String: Int]()
        let tabCount = getTotalTabCount(window: window)
        tabCounts[window.uuidString] = tabCount
        defaults.set(tabCounts, forKey: entryPoint.defaultsKey)
    }

    private func validateTabCount(_ window: WindowUUID, entryPoint: EntryPoint) {
        defer {
            // After validating the tab count, we make sure to remove the count
            // in preferences until the next time that the app is backgrounded.
            // This is to prevent false-positives that can occur if a stale count
            // is still in preferences and the app crashes. If the user removed
            // any tabs during this time, it means the next launch there will be
            // fewer tabs than recorded and we'll send the event erroneously.
            invalidateTabCount(for: window, entryPoint: entryPoint)
        }
        guard tabManagerAvailable(for: window) else {
            logger.log("Can't validate tab count. Tab manager unavailable.",
                       level: .info,
                       category: .tabs,
                       extra: ["uuid": window.uuidString]
            )
            return
        }

        guard let tabCounts = defaults.object(forKey: entryPoint.defaultsKey) as? [String: Int],
              let expectedTabCount = tabCounts[window.uuidString] else { return }
        let currentTabCount = getTotalTabCount(window: window)

        if expectedTabCount > 1 && (expectedTabCount - currentTabCount) > 1 {
            // Potential tab loss bug detected. Log a MetricKit error.
            sendTelemetryTabLossDetectedEvent(
                expected: expectedTabCount,
                actual: currentTabCount,
                entryPoint: entryPoint
            )
        }
    }

    private func invalidateTabCount(for window: WindowUUID, entryPoint: EntryPoint) {
        guard var tabCounts = defaults.object(forKey: entryPoint.defaultsKey) as? [String: Int] else { return }
        tabCounts.removeValue(forKey: window.uuidString)
        defaults.set(tabCounts, forKey: entryPoint.defaultsKey)
    }

    /// It's possible for this telemetry helper to be called during onboarding flow before
    /// any tab managers have been configured.
    private func tabManagerAvailable(for uuid: WindowUUID) -> Bool {
        guard let info = windowManager.windows[uuid],
              info.tabManager != nil else { return false }
        return true
    }

    private func getTotalTabCount(window: WindowUUID) -> Int {
        assert(tabManagerAvailable(for: window), "getTabCount() should not be called prior to TabManager config.")
        return windowManager.tabManager(for: window).normalTabs.count
    }

    private func sendTelemetryTabLossDetectedEvent(expected: Int, actual: Int, entryPoint: EntryPoint) {
        logger.log("Tab loss detected \(entryPoint.logInfo).",
                   level: .fatal,
                   category: .tabs,
                   extra: [
                    "expected": String(expected),
                    "actual": String(actual),
                    "windows": String(windowManager.windows.count)
                   ]
        )

        // Only send the telemetry event for the foregrounding log so we don't mess with our existing metrics
        // around tab loss
        if case .backgroundForeground = entryPoint {
            telemetryWrapper.recordEvent(
                category: .information,
                method: .error,
                object: .app,
                value: .tabLossDetected
            )
        }
    }
}
