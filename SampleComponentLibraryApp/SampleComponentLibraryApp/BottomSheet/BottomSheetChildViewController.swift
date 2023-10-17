// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Foundation
import UIKit

class BottomSheetChildViewController: UIViewController, BottomSheetChild, Themeable {
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

    private lazy var contentLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
    }

    private var heightConstraint: NSLayoutConstraint!

    init(themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.themeManager = themeManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        listenForThemeChange(view)
        applyTheme()

        contentLabel.text = String(repeating: "\(loremIpsum)", count: 1)

        setupView()
    }

    private func setupView() {
        view.addSubview(contentLabel)

        NSLayoutConstraint.activate([
            contentLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            contentLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 48),
            contentLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            contentLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -48)
        ])
    }

    // MARK: BottomSheetChild

    func willDismiss() {}

    // MARK: Themeable

    func applyTheme() {
        contentLabel.textColor = themeManager.currentTheme.colors.textPrimary
        view.backgroundColor = themeManager.currentTheme.colors.layer1
    }
}
