// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import UIKit

@testable import Client

class MockToolbarHelper: ToolbarHelperInterface, FeatureFlaggable {
    private enum UX {
        static let backgroundAlphaForBlur: CGFloat = 0.85
        static let novaToolbarBackgroundAlphaForBlur: CGFloat = 0.90
    }

    var reduceTransparencyEnabled = false
    var isSwipingTabsEnabled = true
    var userInterfaceIdiom: UIUserInterfaceIdiom = .phone
    var shouldShowNavigationToolbar = true
    var shouldShowTopTabs = false

    @MainActor
    var isReduceTransparencyEnabled: Bool { reduceTransparencyEnabled }

    @MainActor
    var glassEffectAlpha: CGFloat {
        guard shouldBlur() else { return 1 }
        if #available(iOS 26, *) { return .zero } else { return UX.backgroundAlphaForBlur }
    }

    @MainActor
    var novaToolbarGlassEffectAlpha: CGFloat {
        if featureFlagsProvider.isEnabled(.novaDesign), #available(iOS 26, *) {
            return glassEffectAlpha
        }
        // for Nova themes on iOS 18 we want to use a different alpha for both top and bottom toolbar
        return shouldBlur() ? UX.novaToolbarBackgroundAlphaForBlur : glassEffectAlpha
    }

    func shouldShowNavigationToolbar(for traitCollection: UITraitCollection) -> Bool {
        return shouldShowNavigationToolbar
    }

    func shouldShowTopTabs(for traitCollection: UITraitCollection) -> Bool {
        return shouldShowTopTabs
    }

    @MainActor
    func shouldBlur() -> Bool {
        return !isReduceTransparencyEnabled
    }

    func getLockIconState(hasOnlySecureContent: Bool, isWebsiteMode: Bool) -> LockIconState {
        return ToolbarHelper.computeLockIconState(hasOnlySecureContent: hasOnlySecureContent, isWebsiteMode: isWebsiteMode)
    }
}
