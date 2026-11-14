// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

// An empty cell that takes the space of a tile while the top sites are still loading
class EmptyTopSiteCell: UICollectionViewCell, ReusableCell {
    enum UX {
        static let horizontalMargin: CGFloat = 8
    }

    private lazy var emptyBG: UIView = .build { view in
        view.layer.cornerRadius = HomepageUX.generalCornerRadius
    }

    // Same font as the tile title so the placeholder matches a real tile's height.
    private lazy var titleSpacer: UILabel = .build { label in
        label.font = FXFontStyles.Bold.caption1.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.text = " "
        label.isAccessibilityElement = false
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        contentView.addSubview(emptyBG)
        contentView.addSubview(titleSpacer)

        NSLayoutConstraint.activate([
            emptyBG.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emptyBG.widthAnchor.constraint(equalToConstant: HomepageUX.imageBackgroundSize.width),
            emptyBG.heightAnchor.constraint(equalToConstant: HomepageUX.imageBackgroundSize.height),
            emptyBG.topAnchor.constraint(equalTo: contentView.topAnchor),

            titleSpacer.topAnchor.constraint(equalTo: emptyBG.bottomAnchor, constant: TopSiteCell.UX.textSafeSpace),
            titleSpacer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleSpacer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
}

// MARK: - ThemeApplicable
extension EmptyTopSiteCell: ThemeApplicable {
    func applyTheme(theme: Theme) {
        emptyBG.layer.borderColor = theme.colors.borderPrimary.cgColor
    }
}
