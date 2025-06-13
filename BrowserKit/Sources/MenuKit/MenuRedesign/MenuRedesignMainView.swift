// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import ComponentLibrary

public final class MenuRedesignMainView: UIView,
                                         ThemeApplicable {
    private struct UX {
        static let headerTopMargin: CGFloat = 15
        static let horizontalMargin: CGFloat = 16
        static let closeButtonSize: CGFloat = 30
        static let headerTopMarginWithButton: CGFloat = 8
    }

    public var closeButtonCallback: (() -> Void)?

    // MARK: - UI Elements
    private var tableView: MenuRedesignTableView = .build()
    private lazy var closeButton: CloseButton = .build { button in
        button.addTarget(self, action: #selector(self.closeTapped), for: .touchUpInside)
    }

    private var viewConstraints: [NSLayoutConstraint] = []

    // MARK: - UI Setup
    private func setupView(with data: [MenuSection]) {
        self.removeConstraints(viewConstraints)
        viewConstraints.removeAll()
        self.addSubview(tableView)
        if let section = data.first(where: { $0.isHomepage }), section.isHomepage {
            self.addSubview(closeButton)
            viewConstraints.append(contentsOf: [
                closeButton.topAnchor.constraint(equalTo: self.topAnchor, constant: UX.headerTopMargin),
                closeButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -UX.horizontalMargin),
                closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize),
                closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize),

                tableView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: UX.headerTopMarginWithButton),
                tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
            ])
        } else {
            self.closeButton.removeFromSuperview()
            viewConstraints.append(contentsOf: [
                tableView.topAnchor.constraint(equalTo: self.topAnchor, constant: UX.headerTopMargin),
                tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
            ])
        }
        NSLayoutConstraint.activate(viewConstraints)
    }

    public func setupAccessibilityIdentifiers(menuA11yId: String,
                                              menuA11yLabel: String,
                                              closeButtonA11yLabel: String,
                                              closeButtonA11yIdentifier: String) {
        let closeButtonViewModel = CloseButtonViewModel(a11yLabel: closeButtonA11yLabel,
                                                        a11yIdentifier: closeButtonA11yIdentifier)
        closeButton.configure(viewModel: closeButtonViewModel)
        tableView.setupAccessibilityIdentifiers(menuA11yId: menuA11yId, menuA11yLabel: menuA11yLabel)
    }

    // MARK: - Interface
    public func reloadDataView(with data: [MenuSection]) {
        setupView(with: data)
        tableView.reloadTableView(with: data)
    }

    // MARK: - Callbacks
    @objc
    private func closeTapped() {
        closeButtonCallback?()
    }

    // MARK: - ThemeApplicable
    public func applyTheme(theme: Theme) {
        backgroundColor = .clear
        tableView.applyTheme(theme: theme)
    }
}
