// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// Helper utility that aims to detect potential bugs in production which could result in tab loss.
/// Note that it's possible for this telemetry helper to be called during onboarding flow before
/// any tab managers have been configured, we need to be sure to gracefully handle any
/// nil return values when querying `tabManager(for:)`
@MainActor
final class TabErrorTelemetryHelper {
    static let shared = TabErrorTelemetryHelper()

    private let telemetryWrapper: TelemetryWrapperProtocol
    private let defaults: UserDefaultsInterface
    private let windowManager: WindowManager
    private let logger: Logger

    /// Threshold (≥) for which we fire a tab loss event.
    private static let tabLossCountThreshold = 3
    private static let significantLossPercentThreshold = 0.20

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

    init(logger: Logger = DefaultLogger.shared,
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
    nonisolated func recordTabCountForBackgroundedScene(_ window: WindowUUID) {
        ensureMainThread { self.recordTabCount(window, entryPoint: .backgroundForeground) }
    }

    /// Validates the tab count when the app is foregrounded to ensure the
    /// count is consistent with the count upon backgrounding.
    nonisolated func validateTabCountForForegroundedScene(_ window: WindowUUID) {
        ensureMainThread { self.validateTabCount(window, entryPoint: .backgroundForeground) }
    }

    func recordTabCountAfterPreservingTabs(_ window: WindowUUID) {
        recordTabCount(window, entryPoint: .preserveRestore)
    }

    func validateTabCountAfterRestoringTabs(_ window: WindowUUID) {
        validateTabCount(window, entryPoint: .preserveRestore)
    }

    // MARK: - Internal Utility

    private func recordTabCount(_ window: WindowUUID, entryPoint: EntryPoint) {
        var tabCounts = defaults.object(forKey: entryPoint.defaultsKey) as? [String: Int] ?? [String: Int]()
        guard let tabCount = getTotalTabCount(window: window) else { return }
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

        guard let tabCounts = defaults.object(forKey: entryPoint.defaultsKey) as? [String: Int],
              let expectedTabCount = tabCounts[window.uuidString] else { return }
        guard let currentTabCount = getTotalTabCount(window: window) else {
            logger.log("Can't validate tab count. Tab manager unavailable.",
                       level: .info,
                       category: .tabs,
                       extra: ["uuid": window.uuidString]
            )
            return
        }

        if Self.tabDiscrepancyDetected(expectedTabCount: expectedTabCount,
                                       currentTabCount: currentTabCount) {
            let significantEvent = Self.isSignificantTabLossEvent(expectedTabCount: expectedTabCount,
                                                                  currentTabCount: currentTabCount)
            sendTelemetryTabLossDetectedEvent(
                expected: expectedTabCount,
                actual: currentTabCount,
                entryPoint: entryPoint,
                significantLossDetected: significantEvent
            )
        }
    }

    static func tabDiscrepancyDetected(expectedTabCount: Int, currentTabCount: Int) -> Bool {
        if expectedTabCount > 1 && (expectedTabCount - currentTabCount) > 1 {
            // Potential tab loss bug detected. Log a MetricKit error.
            return true
        }
        return false
    }

    static func isSignificantTabLossEvent(expectedTabCount: Int, currentTabCount: Int) -> Bool {
        // Here we determine whether the discrepancy is a minor deviation from the expected tab count
        // or a major loss of the user's tabs. The criteria for "major loss" is currently considered
        // a scenario where: the missing tab count is ≥ our threshold (3) _and_ comprises a significant
        // percentage of the user's total tabs.
        let missingCount = (expectedTabCount - currentTabCount)
        let percentLost: Double
        percentLost = Double(missingCount) / Double(expectedTabCount)

        return missingCount >= tabLossCountThreshold &&
        percentLost >= significantLossPercentThreshold
    }

    private func invalidateTabCount(for window: WindowUUID, entryPoint: EntryPoint) {
        guard var tabCounts = defaults.object(forKey: entryPoint.defaultsKey) as? [String: Int] else { return }
        tabCounts.removeValue(forKey: window.uuidString)
        defaults.set(tabCounts, forKey: entryPoint.defaultsKey)
    }

    private func getTotalTabCount(window: WindowUUID) -> Int? {
        guard windowManager.windows.keys.contains(window),
              let tabManager = windowManager.tabManager(for: window) else {
            return nil
        }
        return tabManager.normalTabs.count
    }

    private func sendTelemetryTabLossDetectedEvent(expected: Int,
                                                   actual: Int,
                                                   entryPoint: EntryPoint,
                                                   significantLossDetected: Bool) {
        let extras: [String: String] = [
            "expected": String(expected),
            "actual": String(actual),
            "missing": String(expected - actual),
            "windows": String(windowManager.windows.count)
           ]

        if significantLossDetected {
            logger.log("Tab loss detected \(entryPoint.logInfo).",
                       level: .fatal,
                       category: .tabs,
                       extra: extras)
        }

        // Only send the telemetry event for the foregrounding log so we don't mess with our existing metrics
        // around tab loss
        if case .backgroundForeground = entryPoint {
            let event: TelemetryWrapper.EventValue = significantLossDetected ? .tabLossDetected : .tabCountDiscrepancy
            telemetryWrapper.recordEvent(
                category: .information,
                method: .error,
                object: .app,
                value: event,
                extras: extras
            )
        }
    }
}
