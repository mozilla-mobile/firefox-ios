// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

protocol ToolbarHelperInterface {
    var isToolbarRefactorEnabled: Bool { get }
    var isToolbarTranslucencyEnabled: Bool { get }
    var isReduceTransparencyEnabled: Bool { get }
    var glassEffectAlpha: CGFloat { get }

    func shouldShowNavigationToolbar(for traitCollection: UITraitCollection) -> Bool
    func shouldShowTopTabs(for traitCollection: UITraitCollection) -> Bool
    func shouldBlur() -> Bool
    func backgroundAlpha() -> CGFloat
}

final class ToolbarHelper: ToolbarHelperInterface {
    private enum UX {
        static let backgroundAlphaForBlur: CGFloat = 0.85
    }

    var isToolbarRefactorEnabled: Bool {
        FxNimbus.shared.features.toolbarRefactorFeature.value().enabled
    }

    var isToolbarTranslucencyEnabled: Bool {
        FxNimbus.shared.features.toolbarRefactorFeature.value().translucency
    }

    var isReduceTransparencyEnabled: Bool {
        UIAccessibility.isReduceTransparencyEnabled
    }

    var glassEffectAlpha: CGFloat {
        guard shouldBlur() else { return 1 }
        #if canImport(FoundationModels)
        if #available(iOS 26, *) { return .zero } else { return UX.backgroundAlphaForBlur }
        #else
            return UX.backgroundAlphaForBlur
        #endif
    }

    func shouldShowNavigationToolbar(for traitCollection: UITraitCollection) -> Bool {
        return traitCollection.verticalSizeClass != .compact
               && traitCollection.horizontalSizeClass != .regular
    }

    func shouldShowTopTabs(for traitCollection: UITraitCollection) -> Bool {
        return traitCollection.verticalSizeClass == .regular
               && traitCollection.horizontalSizeClass == .regular
    }

    func shouldBlur() -> Bool {
        return isToolbarRefactorEnabled &&
            isToolbarTranslucencyEnabled &&
            !isReduceTransparencyEnabled
    }

    func backgroundAlpha() -> CGFloat {
        guard shouldBlur() else { return 1.0 }

        return UX.backgroundAlphaForBlur
    }
}
