// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import ComponentLibrary

public final class MenuRedesignMainView: UIView,
                                         ThemeApplicable {
    private struct UX {
        static let headerTopMargin: CGFloat = 24
        static let horizontalMargin: CGFloat = 16
        static let closeButtonSize: CGFloat = 30
        static let headerTopMarginWithButton: CGFloat = 8
    }

    public var closeButtonCallback: (() -> Void)?
    public var onCalculatedHeight: ((CGFloat, _ isExpanded: Bool) -> Void)?

    // MARK: - UI Elements
    private var tableView: MenuRedesignTableView = .build()
    private lazy var closeButton: CloseButton = .build { button in
        button.addTarget(self, action: #selector(self.closeTapped), for: .touchUpInside)
    }
    public var siteProtectionHeader: MenuSiteProtectionsHeader = .build()

    private var viewConstraints: [NSLayoutConstraint] = []

<<<<<<< HEAD
    // MARK: - UI Setup
    private func setupView(with data: [MenuSection]) {
=======
    // MARK: - Properties
    private var isMenuDefaultBrowserBanner = false
    private var menuData: [MenuSection] = []
    private var isBrowserDefault = false
    private var bannerShown = false

    // MARK: - UI Setup
    override public func layoutSubviews() {
        super.layoutSubviews()
        updateMenuHeight(for: menuData)
    }

    private func setupView(with data: [MenuSection], isHeaderBanner: Bool = true) {
>>>>>>> 215cc7e77 (Bugfix FXIOS-12721 ⁃ Shaky menu movemenu when launched after opening a new tab (#27729))
        self.removeConstraints(viewConstraints)
        viewConstraints.removeAll()
        self.addSubview(tableView)
        if let section = data.first(where: { $0.isHomepage }), section.isHomepage {
            self.siteProtectionHeader.removeFromSuperview()
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
        } else if !data.isEmpty {
            self.closeButton.removeFromSuperview()
            self.addSubview(siteProtectionHeader)
            viewConstraints.append(contentsOf: [
                siteProtectionHeader.topAnchor.constraint(equalTo: self.topAnchor, constant: UX.headerTopMargin),
                siteProtectionHeader.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                siteProtectionHeader.trailingAnchor.constraint(equalTo: self.trailingAnchor),

                tableView.topAnchor.constraint(equalTo: siteProtectionHeader.bottomAnchor,
                                               constant: UX.headerTopMarginWithButton),
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
                                              closeButtonA11yIdentifier: String,
                                              siteProtectionHeaderIdentifier: String) {
        let closeButtonViewModel = CloseButtonViewModel(a11yLabel: closeButtonA11yLabel,
                                                        a11yIdentifier: closeButtonA11yIdentifier)
        closeButton.configure(viewModel: closeButtonViewModel)
        siteProtectionHeader.setupAccessibility(closeButtonA11yLabel: closeButtonA11yLabel,
                                                closeButtonA11yId: closeButtonA11yIdentifier)
        siteProtectionHeader.accessibilityIdentifier = siteProtectionHeaderIdentifier
        tableView.setupAccessibilityIdentifiers(menuA11yId: menuA11yId, menuA11yLabel: menuA11yLabel)
    }

    // MARK: - Interface
    public func reloadDataView(with data: [MenuSection]) {
        setupView(with: data)
        tableView.reloadTableView(with: data)
<<<<<<< HEAD
        updateMenuHeight(for: data)
=======
        handleBannerCallback(with: data)
        menuData = data
>>>>>>> 215cc7e77 (Bugfix FXIOS-12721 ⁃ Shaky menu movemenu when launched after opening a new tab (#27729))
    }

    private func updateMenuHeight(for data: [MenuSection]) {
        let expandedSection = data.first(where: { $0.isExpanded ?? false })
        let isExpanded = expandedSection?.isExpanded ?? false

        // To avoid a glitch when expand the menu, we should not handle this action under DispatchQueue.main.async
        if isExpanded {
            let height = tableView.tableViewContentSize + UX.headerTopMargin
            onCalculatedHeight?(height + siteProtectionHeader.frame.height, isExpanded)
            layoutIfNeeded()
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let height = tableView.tableViewContentSize + UX.headerTopMargin
                if let section = data.first(where: { $0.isHomepage }), section.isHomepage {
                    onCalculatedHeight?(height + UX.closeButtonSize + UX.headerTopMarginWithButton, isExpanded)
                } else {
                    onCalculatedHeight?(height + siteProtectionHeader.frame.height, isExpanded)
                }
                layoutIfNeeded()
            }
        }
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
        siteProtectionHeader.applyTheme(theme: theme)
    }
}
