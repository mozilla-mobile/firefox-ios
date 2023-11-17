/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Common

extension LegacyTheme {
    var isDark: Bool {
        return type(of: self) == DarkTheme.self
    }
}

class EcosiaTheme {
    var primaryBrand: UIColor { .Light.Brand.primary}
    var secondaryBrand: UIColor { UIColor.Photon.Grey60 }
    var border: UIColor { .Light.border }

    var primaryBackground: UIColor { .Light.Background.primary }
    var secondaryBackground: UIColor { .Light.Background.secondary }
    var tertiaryBackground: UIColor { .Light.Background.tertiary }
    var quarternaryBackground: UIColor { .Light.Background.quarternary }
    var barBackground: UIColor { .white }
    var barSeparator: UIColor { UIColor.Photon.Grey20 }
    var impactBackground: UIColor { .Light.Background.primary }
    var impactSeparator: UIColor { UIColor.Photon.Grey40 }
    var treeCounterProgressTotal: UIColor { .Light.Background.tertiary }
    var treeCounterProgressCurrent: UIColor { .Light.Brand.primary }
    var treeCounterProgressBorder: UIColor { .Light.Background.tertiary }

    var ntpCellBackground: UIColor { .Light.Background.primary }
    var ntpBackground: UIColor { .Light.Background.tertiary }
    var ntpIntroBackground: UIColor { .Light.Background.primary }
    var ntpImpactBackground: UIColor { .Light.Background.primary }

    var impactMultiplyCardBackground: UIColor { .Light.Background.primary }
    var trackingSheetBackground: UIColor { .Light.Background.tertiary }
    var moreNewsButton: UIColor { .Light.Button.secondary }
    var newsPlaceholder: UIColor { .Light.Background.secondary }
    
    var actionSheetBackground: UIColor { .Light.Background.primary }
    var actionSheetCancelButton: UIColor { .Light.Button.primaryActive }
    var modalBackground: UIColor { .Light.Background.tertiary }
    var modalHeader: UIColor { .init(red: 0.153, green: 0.322, blue: 0.263, alpha: 1) }
    
    var whatsNewCloseButton: UIColor { .Light.Text.primary }

    var primaryText: UIColor { .Light.Text.primary }
    var primaryTextInverted: UIColor { .Dark.Text.primary }
    var secondaryText: UIColor { .Light.Text.secondary }
    var navigationBarText: UIColor { .Light.Text.primary }
    var tertiaryText: UIColor { .Light.Text.tertiary }

    var primaryIcon: UIColor { .Light.Icon.primary }
    var secondaryIcon: UIColor { .Light.Icon.secondary }
    var decorativeIcon: UIColor { .Light.Icon.decorative }
    
    var highlightedBackground: UIColor { .Light.Background.highlighted }
    var primarySelectedBackground: UIColor { .Light.Background.secondary }
    var secondarySelectedBackground: UIColor { .Light.Background.secondary }

    var primaryButton: UIColor { .Light.Button.primary }
    var primaryButtonActive: UIColor { .Light.Button.primaryActive }
    var secondaryButton: UIColor { .Light.Button.secondary }
    var secondaryButtonContent: UIColor { .Light.Button.secondaryContent }
    var secondaryButtonBackground: UIColor { .Light.Button.secondaryBackground }
    var activeTransparentBackground: UIColor { .Light.Button.activeTransparentBackground }
    
    var textfieldPlaceholder: UIColor { .Light.Text.secondary }
    var textfieldIconTint: UIColor { .Light.Button.primary }
    var personalCounterSelection: UIColor { UIColor.Photon.Grey20 }
    var privateButtonBackground: UIColor { UIColor.Photon.Grey70 }

    var modalOverlayBackground: UIColor { UIColor(rgb: 0x333333).withAlphaComponent(0.4) }

    var segmentSelectedText: UIColor { .Light.Text.primary }
    var segmentBackground: UIColor { .Light.Background.secondary }

    var warning: UIColor { .Light.State.warning }
    var information: UIColor { .Light.State.information }
    var disabled: UIColor { .Light.State.disabled }

    var tabBackground: UIColor { .Light.Background.primary }
    var tabSelectedBackground: UIColor { .Light.Button.primary }
    var tabSelectedPrivateBackground: UIColor { .Dark.Background.secondary }

    var toastImageTint: UIColor { .init(red: 0.847, green: 1, blue: 0.502, alpha: 1) }
    var autocompleteBackground: UIColor { .Light.Background.primary }
    var welcomeBackground: UIColor { .Light.Background.tertiary }
    var welcomeElementBackground: UIColor { .Light.Background.primary }
    
    var homePanelBackground: UIColor { return .Light.Background.tertiary }
}

final class DarkEcosiaTheme: EcosiaTheme {
    override var primaryBrand: UIColor { .Dark.Brand.primary}
    override var secondaryBrand: UIColor { .white }
    override var border: UIColor { .Dark.border }

    override var primaryBackground: UIColor { .Dark.Background.primary }
    override var secondaryBackground: UIColor { .Dark.Background.secondary }
    override var tertiaryBackground: UIColor { .Dark.Background.tertiary }
    override var quarternaryBackground: UIColor { .Dark.Background.quarternary }
    override var barBackground: UIColor { .Dark.Background.secondary }
    override var barSeparator: UIColor { UIColor.Photon.Grey60 }
    override var impactBackground: UIColor { .Dark.Background.tertiary }
    override var impactSeparator: UIColor { UIColor.Photon.Grey60 }
    override var treeCounterProgressTotal: UIColor { .Dark.Background.secondary }
    override var treeCounterProgressCurrent: UIColor { .Dark.Brand.primary }
    override var treeCounterProgressBorder: UIColor { .Dark.Background.tertiary }

    override var ntpCellBackground: UIColor { .Dark.Background.tertiary }
    override var ntpBackground: UIColor { .Dark.Background.primary }
    override var ntpImpactBackground: UIColor { .Dark.Background.secondary}
    override var ntpIntroBackground: UIColor { .Dark.Background.tertiary }

    override var impactMultiplyCardBackground: UIColor { .Dark.Background.tertiary }
    override var trackingSheetBackground: UIColor { .Dark.Background.secondary }
    override var moreNewsButton: UIColor { .Dark.Background.primary }
    override var newsPlaceholder: UIColor { .Grey.fifty }

    override var actionSheetBackground: UIColor { .Dark.Background.secondary }
    override var actionSheetCancelButton: UIColor { .Dark.Button.primaryActive }
    override var modalBackground: UIColor { .Dark.Background.secondary }
    override var modalHeader: UIColor { .Dark.Background.secondary }
    
    override var whatsNewCloseButton: UIColor { .white }

    override var primaryText: UIColor { .Dark.Text.primary}
    override var primaryTextInverted: UIColor { .Light.Text.primary }
    override var secondaryText: UIColor { .Dark.Text.secondary }
    override var navigationBarText: UIColor { .Dark.Text.primary }
    override var tertiaryText: UIColor { .Dark.Text.tertiary }

    override var primaryIcon: UIColor { .Dark.Icon.primary }
    override var secondaryIcon: UIColor { .Dark.Icon.secondary }
    override var decorativeIcon: UIColor { .Dark.Icon.decorative }
    
    override var highlightedBackground: UIColor { .Dark.Background.highlighted }

    override var primarySelectedBackground: UIColor { .Dark.Background.tertiary }
    override var secondarySelectedBackground: UIColor { .init(red: 0.227, green: 0.227, blue: 0.227, alpha: 1) }

    override var primaryButton: UIColor { .Dark.Button.primary }
    override var primaryButtonActive: UIColor { .Dark.Button.primaryActive }
    override var secondaryButton: UIColor { .Dark.Button.secondary }
    override var secondaryButtonContent: UIColor { .Dark.Button.secondaryContent }
    override var secondaryButtonBackground: UIColor { .Dark.Button.secondaryBackground }
    override var activeTransparentBackground: UIColor { .Dark.Button.activeTransparentBackground }

    override var textfieldPlaceholder: UIColor { .Dark.Text.secondary }
    override var textfieldIconTint: UIColor { .Dark.Button.primary }

    override var personalCounterSelection: UIColor { UIColor.Photon.Grey60 }
    override var privateButtonBackground: UIColor { .white }

    override var modalOverlayBackground: UIColor { UIColor(rgb: 0x333333).withAlphaComponent(0.6) }

    override var segmentSelectedText: UIColor { UIColor.Photon.Grey90 }
    override var segmentBackground: UIColor { .Dark.Background.tertiary }

    override var warning: UIColor { .Dark.State.warning }
    override var information: UIColor { .Dark.State.information }
    override var disabled: UIColor { .Dark.State.disabled }

    override var tabBackground: UIColor { .Dark.Background.tertiary }
    override var tabSelectedBackground: UIColor { .Dark.Button.primary }
    override var tabSelectedPrivateBackground: UIColor { .white}

    override var toastImageTint: UIColor { .init(red: 0.153, green: 0.322, blue: 0.263, alpha: 1) }
    override var autocompleteBackground: UIColor { .Dark.Background.secondary }
    override var welcomeBackground: UIColor { .Dark.Background.secondary }
    override var welcomeElementBackground: UIColor { .Dark.Background.secondary }
    
    override var homePanelBackground: UIColor { return .Dark.Background.secondary }
}

extension UIImage {
    convenience init?(themed name: String) {
        let suffix = LegacyThemeManager.instance.current.isDark ? "Dark" : ""
        self.init(named: name + suffix)
    }
}

class EcosiaPrimaryButton: UIButton {
    override var isSelected: Bool {
        set {
            super.isSelected = newValue
            update()
        }
        get {
            return super.isSelected
        }
    }

    override var isHighlighted: Bool {
        set {
            super.isHighlighted = newValue
            update()
        }
        get {
            return super.isHighlighted
        }
    }

    private func update() {
        backgroundColor = (isSelected || isHighlighted) ? .legacyTheme.ecosia.primaryButtonActive : .legacyTheme.ecosia.primaryButton
    }
}
