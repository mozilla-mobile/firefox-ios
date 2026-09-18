// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit

/// Keeps the "Combine Windows" home screen Quick Action in sync with the number of open iPad
/// windows: the action is only offered while the feature is enabled and two or more windows are
/// open. Call `update()` whenever the set of open windows changes (a scene becoming active or
/// disconnecting).
@MainActor
struct MergeWindowsQuickActionController {
    private let quickActions: QuickActions
    private let windowManager: WindowManager
    private let application: UIApplication
    private let featureFlags: FeatureFlagProviding

    init(quickActions: QuickActions = QuickActionsImplementation(),
         windowManager: WindowManager = AppContainer.shared.resolve(),
         application: UIApplication = .shared,
         featureFlags: FeatureFlagProviding = AppContainer.shared.resolve()) {
        self.quickActions = quickActions
        self.windowManager = windowManager
        self.application = application
        self.featureFlags = featureFlags
    }

    /// Adds the merge Quick Action when the feature is enabled and 2+ windows are open,
    /// otherwise removes it.
    func update() {
        if featureFlags.isEnabled(.mergeWindows), windowManager.windows.count >= 2 {
            quickActions.addDynamicApplicationShortcutItemOfType(.mergeWindows, toApplication: application)
        } else {
            quickActions.removeDynamicApplicationShortcutItemOfType(.mergeWindows, fromApplication: application)
        }
    }
}
