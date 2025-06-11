// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class MenuSquaresViewContentCell: UITableViewCell, ReusableCell, ThemeApplicable {
    private struct UX {
        static let contentViewSpacing: CGFloat = 16
    }

    private var contentStackView: UIStackView = .build { stack in
        stack.axis = .horizontal
        stack.spacing = UX.contentViewSpacing
        stack.distribution = .fillEqually
    }

    private var menuData: [MenuSection]
    private var theme: Theme?

    private var horizontalTabsSection: MenuSection? {
        return menuData.first(where: { $0.isHorizontalTabsSection })
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        menuData = []
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.addSubview(contentStackView)

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: self.topAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }

    func reloadData(with data: [MenuSection]) {
        menuData = data
        contentStackView.removeAllArrangedViews()
        guard let horizontalTabsSection else { return }
        for option in horizontalTabsSection.options {
            let squareView: MenuSquareView = .build { [weak self] view in
                guard let self else { return }
                view.configureCellWith(model: option)
                if let theme { view.applyTheme(theme: theme) }
            }
            contentStackView.addArrangedSubview(squareView)
        }
    }

    // MARK: - Theme Applicable
    func applyTheme(theme: Theme) {
        self.theme = theme
        backgroundColor = .clear
        contentStackView.backgroundColor = .clear
    }
}
