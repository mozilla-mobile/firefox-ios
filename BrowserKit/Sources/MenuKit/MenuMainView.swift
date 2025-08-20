// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import ComponentLibrary

public final class MenuMainView: UIView, ThemeApplicable {
    private struct UX {
        static let headerTopMargin: CGFloat = 24
        static let horizontalMargin: CGFloat = 16
        static let closeButtonSize: CGFloat = 30
        static let headerTopMarginWithButton: CGFloat = 8
    }

    public var closeButtonCallback: (() -> Void)?
    public var onCalculatedHeight: ((CGFloat) -> Void)?
    public var bannerButtonCallback: (() -> Void)?
    public var closeBannerButtonCallback: (() -> Void)?

    // MARK: - UI Elements
    private var tableView: MenuTableView = .build()

    public var headerBanner: HeaderBanner = .build()

    public var siteProtectionHeader: MenuSiteProtectionsHeader = .build()

    private var viewConstraints: [NSLayoutConstraint] = []

    // MARK: - Properties
    // If default browser banner sub flag is enabled
    private var isMenuDefaultBrowserBanner = false
    // If FF is the default browser
    private var isBrowserDefault = false
    // If banner was already shown
    private var bannerShown = false
    // If banner is currently visible
    private var isBannerVisible = false

    private var isPhoneLandscape = false
    private var menuData: [MenuSection] = []

    // MARK: - UI Setup
    override public func layoutSubviews() {
        super.layoutSubviews()
        updateMenuHeight(for: menuData)
    }

    private func setupView(with data: [MenuSection], isHeaderBanner: Bool = true) {
        self.removeConstraints(viewConstraints)
        viewConstraints.removeAll()
        self.addSubview(tableView)
        if let section = data.first(where: { $0.isHomepage }), section.isHomepage {
            self.siteProtectionHeader.removeFromSuperview()
            if isHeaderBanner, isMenuDefaultBrowserBanner, !isBrowserDefault, !bannerShown {
                isBannerVisible = true
                self.addSubview(headerBanner)
                viewConstraints.append(contentsOf: [
                    headerBanner.topAnchor.constraint(equalTo: self.topAnchor, constant: UX.headerTopMargin),
                    headerBanner.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                    headerBanner.trailingAnchor.constraint(equalTo: self.trailingAnchor),

                    tableView.topAnchor.constraint(equalTo: headerBanner.bottomAnchor,
                                                   constant: UX.headerTopMarginWithButton),
                    tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                    tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                    tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
                ])
            } else {
                isBannerVisible = false
                headerBanner.removeFromSuperview()
                viewConstraints.append(contentsOf: [
                    tableView.topAnchor.constraint(equalTo: self.topAnchor,
                                                   constant: UX.headerTopMarginWithButton),
                    tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                    tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                    tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
                ])
            }
        } else if !data.isEmpty {
            isBannerVisible = false
            headerBanner.removeFromSuperview()
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
                                              siteProtectionHeaderIdentifier: String,
                                              headerBannerCloseButtonA11yIdentifier: String,
                                              headerBannerCloseButtonA11yLabel: String) {
        headerBanner.setupAccessibility(closeButtonA11yLabel: headerBannerCloseButtonA11yLabel,
                                        closeButtonA11yId: headerBannerCloseButtonA11yIdentifier)
        siteProtectionHeader.setupAccessibility(closeButtonA11yLabel: closeButtonA11yLabel,
                                                closeButtonA11yId: closeButtonA11yIdentifier)
        siteProtectionHeader.accessibilityIdentifier = siteProtectionHeaderIdentifier
    }

    public func setupDetails(title: String,
                             subtitle: String,
                             image: UIImage?,
                             isBannerFlagEnabled: Bool,
                             isBrowserDefault: Bool,
                             bannerShown: Bool) {
        headerBanner.setupDetails(title: title, subtitle: subtitle, image: image)
        isMenuDefaultBrowserBanner = isBannerFlagEnabled
        self.isBrowserDefault = isBrowserDefault
        self.bannerShown = bannerShown
    }

    public func setupMenuMenuOrientation(isPhoneLandscape: Bool) {
        self.isPhoneLandscape = isPhoneLandscape
    }

    public func announceAccessibility(expandedHint: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            UIAccessibility.post(notification: .announcement, argument: expandedHint)

            guard let section = self?.menuData.first,
               let optionalElementIndex = section.options.firstIndex(where: { $0.isOptional }),
               let firstCell = self?.tableView.tableView.visibleCells[optionalElementIndex]
            else { return }

            UIAccessibility.post(notification: .layoutChanged, argument: firstCell)
        }
    }

    // MARK: - Interface
    public func reloadDataView(with data: [MenuSection]) {
        setupView(with: data)
        tableView.reloadTableView(with: data, isBannerVisible: isBannerVisible)
        handleBannerCallback(with: data)
        menuData = data
    }

    private func updateMenuHeight(for data: [MenuSection]) {
        guard !data.isEmpty else { return }
        let expandedSection = data.first(where: { $0.isExpanded ?? false })
        let isExpanded = expandedSection?.isExpanded ?? false

        // To avoid a glitch when expand the menu, we should not handle this action under DispatchQueue.main.async
        if isExpanded {
            let height = tableView.tableViewContentSize + UX.headerTopMargin
            onCalculatedHeight?(height + siteProtectionHeader.frame.height)
            layoutIfNeeded()
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if let section = data.first(where: { $0.isHomepage }), section.isHomepage {
                    let tableViewHeight = tableView.tableViewContentSize
                    let height = isBannerVisible ? tableViewHeight + UX.headerTopMargin : tableViewHeight
                    self.setHeightForHomepageMenu(height: height)
                } else {
                    onCalculatedHeight?(tableView.tableViewContentSize +
                                        UX.headerTopMargin +
                                        siteProtectionHeader.frame.height)
                }
                layoutIfNeeded()
            }
        }
    }

    private func setHeightForHomepageMenu(height: CGFloat) {
        if isMenuDefaultBrowserBanner {
            let headerBannerHeight = headerBanner.frame.height
            let calculatedHeight = isBannerVisible ? height + headerBannerHeight : height
            self.onCalculatedHeight?(calculatedHeight)
        } else {
            self.onCalculatedHeight?(height)
        }
    }

    private func handleBannerCallback(with data: [MenuSection]) {
        headerBanner.closeButtonCallback = { [weak self] in
            self?.setupView(with: data, isHeaderBanner: false)
            self?.bannerShown = true
            self?.isBannerVisible = false
            self?.tableView.reloadTableView(with: self?.menuData ?? [], isBannerVisible: self?.isBannerVisible ?? false)
            self?.updateMenuHeight(for: self?.menuData ?? [])
            self?.closeBannerButtonCallback?()
        }
        headerBanner.bannerButtonCallback = { [weak self] in
            self?.bannerButtonTapped()
        }
    }

    // MARK: - Callbacks
    @objc
    private func closeTapped() {
        closeButtonCallback?()
    }

    @objc
    private func bannerButtonTapped() {
        bannerButtonCallback?()
    }

    // MARK: - ThemeApplicable
    public func applyTheme(theme: Theme) {
        backgroundColor = .clear
        tableView.applyTheme(theme: theme)
        siteProtectionHeader.applyTheme(theme: theme)
        headerBanner.applyTheme(theme: theme)
    }
}
