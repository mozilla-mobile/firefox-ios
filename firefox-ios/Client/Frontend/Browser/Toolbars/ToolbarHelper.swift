// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

struct LockIconState: Equatable {
    let imageName: String?
    let a11yId: String?
    let needsTheming: Bool

    /// No lock icon is shown, on the homepage where there is no secure content information.
    static let none = LockIconState(imageName: nil, a11yId: nil, needsTheming: true)
}

extension LockIconState {
    /// - Parameters:
    ///   - hasOnlySecureContent: Whether the page has only secure content, `nil` when unknown (no icon is shown).
    ///   - isWebsiteMode: `false` for pages where the icon is hidden, like reader mode.
    init(hasOnlySecureContent: Bool?, isWebsiteMode: Bool) {
        guard let hasOnlySecureContent else {
            self = .none
            return
        }

        let imageName = hasOnlySecureContent ?
            StandardImageIdentifiers.Small.shieldCheckmarkFill :
            StandardImageIdentifiers.Small.shieldSlashFillMulticolor
        let a11yId = hasOnlySecureContent ?
            AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon :
            AccessibilityIdentifiers.Browser.AddressToolbar.lockIconOff

        self.init(
            imageName: isWebsiteMode ? imageName : nil,
            a11yId: a11yId,
            needsTheming: hasOnlySecureContent
        )
    }
}

protocol ToolbarHelperInterface {
    var isSwipingTabsEnabled: Bool { get }
    var userInterfaceIdiom: UIUserInterfaceIdiom { get }

    @MainActor
    var isReduceTransparencyEnabled: Bool { get }

    @MainActor
    var glassEffectAlpha: CGFloat { get }

    @MainActor
    var novaToolbarGlassEffectAlpha: CGFloat { get }

    func shouldShowNavigationToolbar(for traitCollection: UITraitCollection) -> Bool
    func shouldShowTabStrip(for traitCollection: UITraitCollection) -> Bool

    @MainActor
    func shouldBlur() -> Bool
}

final class ToolbarHelper: ToolbarHelperInterface, FeatureFlaggable {
    private enum UX {
        static let backgroundAlphaForBlur: CGFloat = 0.85
        static let novaToolbarBackgroundAlphaForBlur: CGFloat = 0.90
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

    @MainActor
    var novaToolbarGlassEffectAlpha: CGFloat {
        guard featureFlagsProvider.isEnabled(.novaDesign), #unavailable(iOS 26) else {
            return glassEffectAlpha
        }
        // for Nova themes on iOS 18 we want to use a different alpha for both top and bottom toolbar
        return shouldBlur() ? UX.novaToolbarBackgroundAlphaForBlur : glassEffectAlpha
    }

    func shouldShowNavigationToolbar(for traitCollection: UITraitCollection) -> Bool {
        return traitCollection.verticalSizeClass != .compact
               && traitCollection.horizontalSizeClass != .regular
    }

    func shouldShowTabStrip(for traitCollection: UITraitCollection) -> Bool {
        return traitCollection.verticalSizeClass == .regular
               && traitCollection.horizontalSizeClass == .regular
    }

    @MainActor
    func shouldBlur() -> Bool {
        return !isReduceTransparencyEnabled
    }

    @MainActor
    init(
        userInterfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
    ) {
        self.userInterfaceIdiom = userInterfaceIdiom
    }
}
