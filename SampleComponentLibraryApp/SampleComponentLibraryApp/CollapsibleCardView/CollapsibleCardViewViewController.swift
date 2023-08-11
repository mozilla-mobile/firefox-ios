// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import ComponentLibrary
import Common
import Foundation
import UIKit

class CollapsibleCardViewViewController: UIViewController {
    class CardContentView: UIView, ThemeApplicable {
        lazy var contentLabel: UILabel = .build { label in
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
        }

        // MARK: - Inits
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupView()
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func applyTheme(theme: Common.Theme) {
            contentLabel.textColor = theme.colors.textPrimary
        }

        private func setupView() {
            addSubview(contentLabel)

            NSLayoutConstraint.activate([
                contentLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
                contentLabel.topAnchor.constraint(equalTo: topAnchor),
                contentLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
                contentLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
            ])
        }
    }

    private let loremIpsum =
    """
    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna
    aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
    Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur
    sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    """

    private lazy var cardView: CollapsibleCardView = .build { _ in }
    private lazy var contentView: CardContentView = .build { _ in }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()

        view.backgroundColor = .white
        contentView.contentLabel.text = loremIpsum
        let viewModel = CollapsibleCardViewModel(
            contentView: contentView,
            cardViewA11yId: "CollapsibleCardView",
            title: "Collapsible Card View Title",
            titleA11yId: "CollapsibleCardViewTitle",
            expandButtonA11yId: "CollapsibleCardViewExpandButton",
            expandButtonA11yLabelExpanded: "Collapse card",
            expandButtonA11yLabelCollapsed: "Expand card")
        cardView.configure(viewModel)

        let themeManager: ThemeManager = AppContainer.shared.resolve()
        cardView.applyTheme(theme: themeManager.currentTheme)
    }

    private func setupView() {
        view.addSubview(cardView)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cardView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor,
                                             constant: -20)
        ])
    }
}
