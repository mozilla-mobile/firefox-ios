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
        stack.accessibilityContainerType = .semanticGroup
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
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // We override this method, for handling taps on MenuSquareView views
    // This may be a temporary fix
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.isHidden || self.alpha == 0 || !self.isUserInteractionEnabled {
            return nil
        }
        for subview in contentStackView.arrangedSubviews.reversed() {
            let convertedPoint = self.convert(point, to: subview)
            if let hit = subview.hitTest(convertedPoint, with: event) {
                return hit
            }
        }
        return nil
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

    func reloadData(with data: [MenuSection], and groupA11yLabel: String?) {
        menuData = data
        setupHorizontalTabs()
        contentStackView.accessibilityLabel = groupA11yLabel
    }

    private func setupHorizontalTabs() {
        contentStackView.removeAllArrangedViews()
        guard let horizontalTabsSection else { return }
        for option in horizontalTabsSection.options {
            let squareView: MenuSquareView = .build { [weak self] view in
                guard let self else { return }
                view.configureCellWith(model: option)
                if let theme { view.applyTheme(theme: theme) }
                view.cellTapCallback = {
                    option.action?()
                }
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
