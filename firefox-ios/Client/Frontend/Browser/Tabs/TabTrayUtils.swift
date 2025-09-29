// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol TabTrayUtils {
    @MainActor
    var isTabTrayUIExperimentsEnabled: Bool { get }
    @MainActor
    var isTabTrayTranslucencyEnabled: Bool { get }
    @MainActor
    var isReduceTransparencyEnabled: Bool { get }
    @MainActor
    var segmentedControlHeight: CGFloat { get }
    @MainActor
    func shouldDisplayExperimentUI() -> Bool
    @MainActor
    func shouldBlur() -> Bool
    @MainActor
    func backgroundAlpha() -> CGFloat
}

/// Tiny utility to simplify checking for availability of the tab tray features
@MainActor
struct DefaultTabTrayUtils: FeatureFlaggable, TabTrayUtils {
    private enum UX {
        static let backgroundAlphaForBlur: CGFloat = 0.85
        static let segmentedControlHeight: CGFloat = 53
        static let segmentedControlHeightIOS26: CGFloat = segmentedControlHeight + 16
    }

    var isTabTrayUIExperimentsEnabled: Bool {
        return featureFlags.isFeatureEnabled(.tabTrayUIExperiments, checking: .buildOnly)
    }

    var isTabTrayTranslucencyEnabled: Bool {
        return featureFlags.isFeatureEnabled(.tabTrayTranslucency, checking: .buildOnly)
    }

    var isReduceTransparencyEnabled: Bool {
        UIAccessibility.isReduceTransparencyEnabled
    }

    var segmentedControlHeight: CGFloat {
        if #available(iOS 26.0, *) {
            return shouldDisplayExperimentUI() ? UX.segmentedControlHeightIOS26 : 0
        } else {
            return shouldDisplayExperimentUI() ? UX.segmentedControlHeight : 0
        }
    }

    func shouldDisplayExperimentUI() -> Bool {
        return isTabTrayUIExperimentsEnabled && UIDevice.current.userInterfaceIdiom != .pad
    }

    func shouldBlur() -> Bool {
        return isTabTrayUIExperimentsEnabled && isTabTrayTranslucencyEnabled && !isReduceTransparencyEnabled
    }

    func backgroundAlpha() -> CGFloat {
        guard shouldBlur() else { return 1.0 }

        return UX.backgroundAlphaForBlur
    }
}
