// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

class ReaderModeSettingsButton: UIButton, ThemeApplicable {
    public struct UX {
        public static let verticalInset: CGFloat = 16
        public static let horizontalInset: CGFloat = 16
    }

    var fontType: ReaderModeFontType = .sansSerif

    override init(frame: CGRect) {
        super.init(frame: frame)

        configuration = UIButton.Configuration.plain()

        let contentInsets = NSDirectionalEdgeInsets(top: UX.verticalInset,
                                                    leading: UX.horizontalInset,
                                                    bottom: UX.verticalInset,
                                                    trailing: UX.horizontalInset)
        configuration?.contentInsets = contentInsets
        contentHorizontalAlignment = .center
        titleLabel?.adjustsFontForContentSizeCategory = true
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(fontType: ReaderModeFontType) {
        self.fontType = fontType

        switch fontType {
        case .sansSerif,
             .sansSerifBold:
            let font = UIFont(
                name: "SF-Pro-Text-Regular",
                size: LegacyDynamicFontHelper.defaultHelper.ReaderStandardFontSize
            )
            updateFont(font)
        case .serif,
             .serifBold:
            let font = UIFont(
                name: "NewYorkMedium-Regular",
                size: LegacyDynamicFontHelper.defaultHelper.ReaderStandardFontSize
            )
            updateFont(font)
        }
    }

    // MARK: ThemeApplicable
    public func applyTheme(theme: Theme) {
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
