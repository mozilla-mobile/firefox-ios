// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

class ReaderModeSettingsButton: UIButton {
    public struct UX {
        public static let verticalInset: CGFloat = 16
        public static let horizontalInset: CGFloat = 16
        public static let serifFontName = "NewYorkMedium-Regular"
    }

    var fontType: ReaderModeFontType = .sansSerif
    var sansSerifFont: UIFont? = FXFontStyles.Regular.body.scaledFont()
    var serifFont: UIFont? = UIFont(name: UX.serifFontName,
                                    size: FXFontStyles.Regular.body.systemFont().pointSize)

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
            updateFont(sansSerifFont)
        case .serif,
             .serifBold:
            guard let serifFont else {
                updateFont(serifFont)
                return
            }

            updateFont(UIFontMetrics.default.scaledFont(for: serifFont))
        }
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
