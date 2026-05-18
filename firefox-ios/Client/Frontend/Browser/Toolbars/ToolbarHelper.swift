// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

struct LockIconState: Equatable {
    let imageName: String?
    let a11yId: String?
    let needsTheming: Bool
}

protocol ToolbarHelperInterface {
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

    func getLockIconState(hasOnlySecureContent: Bool, isWebsiteMode: Bool) -> LockIconState
}

final class ToolbarHelper: ToolbarHelperInterface {
    private enum UX {
        static let backgroundAlphaForBlur: CGFloat = 0.85
    }

    var isSwipingTabsEnabled: Bool {
        // Swipe is not enabled on iPads
        return userInterfaceIdiom != .pad
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
		return !isReduceTransparencyEnabled
    }

    @MainActor
    init(userInterfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom) {
        self.userInterfaceIdiom = userInterfaceIdiom
    }

    func getLockIconState(hasOnlySecureContent: Bool, isWebsiteMode: Bool) -> LockIconState {
        let lockIconImageName = hasOnlySecureContent ?
            StandardImageIdentifiers.Small.shieldCheckmarkFill :
            StandardImageIdentifiers.Small.shieldSlashFillMulticolor
        let lockIconButtonA11yId = hasOnlySecureContent ?
            AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon :
            AccessibilityIdentifiers.Browser.AddressToolbar.lockIconOff

        return LockIconState(
            imageName: isWebsiteMode ? lockIconImageName : nil,
            a11yId: lockIconButtonA11yId,
            needsTheming: hasOnlySecureContent
        )
    }
}
