// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import ComponentLibrary
import Common
import Foundation
import UIKit

class CollapsibleCardViewViewController: UIViewController, Themeable {
    private let loremIpsum =
    """
    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna
    aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
    Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur
    sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    """

    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    private lazy var cardView: CollapsibleCardView = .build { _ in }
    private lazy var contentView: CardContentView = .build { _ in }

    init(themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.themeManager = themeManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()

        listenForThemeChange(view)
        applyTheme()

        contentView.contentLabel.text = loremIpsum
        let viewModel = CollapsibleCardViewModel(
            contentView: contentView,
            cardViewA11yId: "CollapsibleCardView",
            title: "Collapsible Card View Title",
            titleA11yId: "CollapsibleCardViewTitle",
            expandButtonA11yId: "CollapsibleCardViewExpandButton",
            expandButtonA11yLabelExpand: "Collapse card",
            expandButtonA11yLabelCollapse: "Expand card")
        cardView.configure(viewModel)

        cardView.applyTheme(theme: themeManager.currentTheme)
        contentView.applyTheme(theme: themeManager.currentTheme)
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

    // MARK: Themeable

    func applyTheme() {
        view.backgroundColor = themeManager.currentTheme.colors.layer1
    }
}
