// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Foundation
import UIKit

final class LabelButtonHeaderCell: UICollectionReusableView,
                                   ReusableCell,
                                   ThemeApplicable {
    private lazy var headerView: LabelButtonHeaderView = .build()

    var titleLabel: UILabel { headerView.titleLabel }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        headerView.prepareForReuse()
    }

    func configure(
        sectionHeaderConfiguration: SectionHeaderConfiguration,
        moreButtonAction: (@MainActor (UIButton) -> Void)? = nil,
        textColor: UIColor?,
        theme: Theme
    ) {
        headerView.configure(
            sectionHeaderConfiguration: sectionHeaderConfiguration,
            moreButtonAction: moreButtonAction,
            textColor: textColor,
            theme: theme
        )
    }

    func applyTheme(theme: Theme) {
        headerView.applyTheme(theme: theme)
    }

    private func setupLayout() {
        addSubview(headerView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
