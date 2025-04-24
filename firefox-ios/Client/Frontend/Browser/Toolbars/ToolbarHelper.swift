// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

class ToolbarHelper {
    private enum UX {
        static let backgroundAlphaForBlur: CGFloat = 0.8
    }

    lazy var isToolbarRefactorEnabled: Bool = {
        FxNimbus.shared.features.toolbarRefactorFeature.value().enabled
    }()

    lazy var isToolbarTranslucencyEnabled: Bool = {
        FxNimbus.shared.features.toolbarRefactorFeature.value().translucency
    }()

    lazy var isReduceTransparencyEnabled: Bool = {
        UIAccessibility.isReduceTransparencyEnabled
    }()

    func shouldShowNavigationToolbar(for traitCollection: UITraitCollection) -> Bool {
        return traitCollection.verticalSizeClass != .compact
               && traitCollection.horizontalSizeClass != .regular
    }

    func shouldShowTopTabs(for traitCollection: UITraitCollection) -> Bool {
        return traitCollection.verticalSizeClass == .regular
               && traitCollection.horizontalSizeClass == .regular
    }

    func backgroundAlpha() -> CGFloat {
        guard isToolbarRefactorEnabled,
              isToolbarTranslucencyEnabled,
              !isReduceTransparencyEnabled
        else { return 1.0 }

        return UX.backgroundAlphaForBlur
    }
}
