// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common

final class MenuTableView: UIView, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, ThemeApplicable {
    struct UX {
        static let topPadding: CGFloat = 24
        static let menuSiteTopPadding: CGFloat = 12
        static let topPaddingWithBanner: CGFloat = 8
        static let distanceBetweenSections: CGFloat = 16
        static let tableViewMargin: CGFloat = 16
    }

    private(set) var tableView: UITableView
    private let tableHelper: MenuTableViewHelper

    private var theme: Theme?

    public var tableViewContentSize: CGFloat {
        tableView.contentSize.height
    }

    override init(frame: CGRect) {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.layoutMargins = UIEdgeInsets(top: 0, left: UX.tableViewMargin, bottom: 0, right: UX.tableViewMargin)
        tableView.sectionFooterHeight = 0
        tableHelper = MenuTableViewHelper(tableView: tableView)
        super.init(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: self.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])

        tableView.register(MenuCell.self, forCellReuseIdentifier: MenuCell.cellIdentifier)
        tableView.register(MenuInfoCell.self, forCellReuseIdentifier: MenuInfoCell.cellIdentifier)
        tableView.register(MenuAccountCell.self, forCellReuseIdentifier: MenuAccountCell.cellIdentifier)
        tableView.register(MenuSquaresViewContentCell.self,
                           forCellReuseIdentifier: MenuSquaresViewContentCell.cellIdentifier)
    }

    func setupAccessibilityIdentifiers(menuA11yId: String, menuA11yLabel: String) {
        tableView.accessibilityIdentifier = menuA11yId
        tableView.accessibilityLabel = menuA11yLabel
    }

    public func reloadTableView(with data: [MenuSection], isBannerVisible: Bool) {
        tableHelper.updateData(data, theme: theme, isBannerVisible: isBannerVisible)
        tableHelper.reload()
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableHelper.menuDataCount()
    }

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return tableHelper.numberOfRowsInSection(section)
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        return tableHelper.cellForRowAt(tableView, indexPath)
    }

    // MARK: - UITableViewDelegate
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableHelper.didSelectRowAt(tableView, indexPath)
    }

    func tableView(
        _ tableView: UITableView,
        heightForHeaderInSection section: Int
    ) -> CGFloat {
        return tableHelper.calculateHeightForHeaderInSection(section)
    }

    func tableView(
        _ tableView: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView? {
        return tableHelper.viewForHeaderInSection(section)
    }

    // MARK: - UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if tableHelper.isHomepage, !UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory {
            scrollView.contentOffset = .zero
            scrollView.showsVerticalScrollIndicator = false
        }
    }

    // MARK: - Theme Applicable
    func applyTheme(theme: Theme) {
        self.theme = theme
        backgroundColor = .clear
        tableView.backgroundColor = .clear
        tableView.separatorColor = theme.colors.borderPrimary
    }
}
