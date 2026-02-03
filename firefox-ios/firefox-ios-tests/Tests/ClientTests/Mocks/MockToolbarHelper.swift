// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class MockToolbarHelper: ToolbarHelperInterface {
    private enum UX {
        static let backgroundAlphaForBlur: CGFloat = 0.85
    }

    var isToolbarRefactorEnabled = true
    var isToolbarTranslucencyEnabled = true
    var isToolbarTranslucencyRefactorEnabled = false
    var isReduceTransparencyEnabled = false
    var isSwipingTabsEnabled = true
    var userInterfaceIdiom: UIUserInterfaceIdiom = .phone
    var shouldShowNavigationToolbar = true
    var shouldShowTopTabs = false

    @MainActor
    var glassEffectAlpha: CGFloat {
        guard shouldBlur() else { return 1 }
        if #available(iOS 26, *) { return .zero } else { return UX.backgroundAlphaForBlur }
    }

    func shouldShowNavigationToolbar(for traitCollection: UITraitCollection) -> Bool {
        return shouldShowNavigationToolbar
    }

    func shouldShowTopTabs(for traitCollection: UITraitCollection) -> Bool {
        return shouldShowTopTabs
    }

    @MainActor
    func shouldBlur() -> Bool {
        return isToolbarRefactorEnabled &&
            isToolbarTranslucencyEnabled &&
            !isReduceTransparencyEnabled
    }

    @MainActor
    func backgroundAlpha() -> CGFloat {
        guard shouldBlur() else { return 1.0 }

        return UX.backgroundAlphaForBlur
    }
}
