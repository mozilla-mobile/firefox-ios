// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

protocol ToolbarHelperInterface {
    var isToolbarRefactorEnabled: Bool { get }
    var isToolbarTranslucencyEnabled: Bool { get }
    var isToolbarTranslucencyRefactorEnabled: Bool { get }
    var isSwipingTabsEnabled: Bool { get }
    var userInterfaceIdiom: UIUserInterfaceIdiom { get }

    @MainActor
    var isReduceTransparencyEnabled: Bool { get }

    @MainActor
    var glassEffectAlpha: CGFloat { get }

    func shouldShowNavigationToolbar(for traitCollection: UITraitCollection) -> Bool
    func shouldShowTopTabs(for traitCollection: UITraitCollection) -> Bool

    @MainActor
    func shouldBlur() -> Bool

    @MainActor
    func backgroundAlpha() -> CGFloat
}

final class ToolbarHelper: ToolbarHelperInterface, FeatureFlaggable {
    private enum UX {
        static let backgroundAlphaForBlur: CGFloat = 0.85
    }

    var isToolbarRefactorEnabled: Bool {
        FxNimbus.shared.features.toolbarRefactorFeature.value().enabled
    }

    var isToolbarTranslucencyEnabled: Bool {
        FxNimbus.shared.features.toolbarRefactorFeature.value().translucency
    }

    var isToolbarTranslucencyRefactorEnabled: Bool {
        featureFlags.isFeatureEnabled(.toolbarTranslucencyRefactor, checking: .buildOnly)
    }

    var isSwipingTabsEnabled: Bool {
        // Swipe is not enabled on iPads
        let isiPad = userInterfaceIdiom == .pad
        return FxNimbus.shared.features.toolbarRefactorFeature.value().swipingTabs && !isiPad
    }

    var userInterfaceIdiom: UIUserInterfaceIdiom

    @MainActor
    var isReduceTransparencyEnabled: Bool {
        UIAccessibility.isReduceTransparencyEnabled
    }

    @MainActor
    var glassEffectAlpha: CGFloat {
        guard shouldBlur() else { return 1 }
        if #available(iOS 26, *) { return .zero } else { return UX.backgroundAlphaForBlur }
    }

    func shouldShowNavigationToolbar(for traitCollection: UITraitCollection) -> Bool {
        return traitCollection.verticalSizeClass != .compact
               && traitCollection.horizontalSizeClass != .regular
    }

    func shouldShowTopTabs(for traitCollection: UITraitCollection) -> Bool {
        return traitCollection.verticalSizeClass == .regular
               && traitCollection.horizontalSizeClass == .regular
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

    @MainActor
    init(userInterfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom) {
        self.userInterfaceIdiom = userInterfaceIdiom
    }
}
