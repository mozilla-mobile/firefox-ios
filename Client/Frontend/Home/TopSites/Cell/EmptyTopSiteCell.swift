// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

// An empty cell to show when a row is incomplete
class EmptyTopSiteCell: UICollectionViewCell, ReusableCell {
    struct UX {
        static let horizontalMargin: CGFloat = 8
    }

    lazy private var emptyBG: UIView = .build { view in
        view.layer.cornerRadius = HomepageViewModel.UX.generalCornerRadius
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

        NSLayoutConstraint.activate([
            emptyBG.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emptyBG.widthAnchor.constraint(equalToConstant: TopSiteItemCell.UX.imageBackgroundSize.width),
            emptyBG.heightAnchor.constraint(equalToConstant: TopSiteItemCell.UX.imageBackgroundSize.height),
            emptyBG.topAnchor.constraint(equalTo: contentView.topAnchor),
        ])
    }
}

// MARK: - ThemeApplicable
extension EmptyTopSiteCell: ThemeApplicable {
    func applyTheme(theme: Theme) {
        emptyBG.layer.borderColor = theme.colors.borderPrimary.cgColor
    }
}
