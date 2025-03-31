// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

class ReaderModeFontTypeButton: UIButton, ThemeApplicable {
    public struct UX {
        public static let verticalInset: CGFloat = 8
        public static let horizontalInset: CGFloat = 16
    }

    var fontType: ReaderModeFontType = .sansSerif
    private var foregroundColorNormal: UIColor = .clear
    private var foregroundColorSelected: UIColor = .clear
    private var backgroundColorNormal: UIColor = .clear

    override init(frame: CGRect) {
        super.init(frame: frame)

        configuration = UIButton.Configuration.plain()
        titleLabel?.adjustsFontForContentSizeCategory = true
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init(fontType: ReaderModeFontType) {
        self.init(frame: .zero)

        self.fontType = fontType
        accessibilityHint = .ReaderModeStyleFontTypeAccessibilityLabel

        let contentInsets = NSDirectionalEdgeInsets(top: UX.verticalInset,
                                                    leading: UX.horizontalInset,
                                                    bottom: UX.verticalInset,
                                                    trailing: UX.horizontalInset)

        switch fontType {
        case .sansSerif,
             .sansSerifBold:
            configuration?.title = .ReaderModeStyleSansSerifFontType
            let font = UIFont(
                name: "SF-Pro-Text-Regular",
                size: LegacyDynamicFontHelper.defaultHelper.ReaderStandardFontSize
            )
            updateFont(font)
        case .serif,
             .serifBold:
            configuration?.title = .ReaderModeStyleSerifFontType
            let font = UIFont(
                name: "NewYorkMedium-Regular",
                size: LegacyDynamicFontHelper.defaultHelper.ReaderStandardFontSize
            )
            updateFont(font)
        }

        configuration?.contentInsets = contentInsets
        contentHorizontalAlignment = .center
    }

    override public func updateConfiguration() {
        guard var updatedConfiguration = configuration else {
            return
        }

        switch state {
        case [.selected]:
            updatedConfiguration.baseForegroundColor = foregroundColorSelected
        default:
            updatedConfiguration.baseForegroundColor = foregroundColorNormal
        }

        updatedConfiguration.background.backgroundColor = backgroundColorNormal
        configuration = updatedConfiguration
    }

    // MARK: ThemeApplicable
    public func applyTheme(theme: Theme) {
        foregroundColorNormal = theme.colors.textDisabled
        foregroundColorSelected = theme.colors.textPrimary
        backgroundColorNormal = .clear
        setNeedsUpdateConfiguration()
    }

    // MARK: Helper
    private func updateFont(_ font: UIFont?) {
        configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = font
            return outgoing
        }
    }
}
