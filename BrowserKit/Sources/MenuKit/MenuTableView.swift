// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common

final class MenuTableView: UIView,
                           UITableViewDelegate,
                           UITableViewDataSource,
                           ThemeApplicable {
    private struct UX {
        static let topPadding: CGFloat = 12
        static let tableViewMargin: CGFloat = 16
        static let distanceBetweenSections: CGFloat = 32
    }

    private var tableView: UITableView
    private var menuData: [MenuSection]
    private var theme: Theme?
    private var isRedesignEnabled: Bool {
        guard let firstSection = menuData.first else {
            tableView.showsVerticalScrollIndicator = true
            return false
        }
        tableView.showsVerticalScrollIndicator = !firstSection.isTopTabsSection
        return firstSection.isTopTabsSection
    }

    var updateHeaderLineView: ((_ isHidden: Bool) -> Void)?

    override init(frame: CGRect) {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.layoutMargins = UIEdgeInsets(top: 0, left: UX.tableViewMargin, bottom: 0, right: UX.tableViewMargin)
        tableView.sectionFooterHeight = 0
        menuData = []
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        setupTableView()
        setupUI()
    }

    private func setupUI() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: self.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(
            MenuCell.self,
            forCellReuseIdentifier: MenuCell.cellIdentifier
        )
    }

    func setupAccessibilityIdentifiers(menuA11yId: String, menuA11yLabel: String) {
        tableView.accessibilityIdentifier = menuA11yId
        tableView.accessibilityLabel = menuA11yLabel
    }

    // MARK: - UITableView Methods
    func numberOfSections(in tableView: UITableView) -> Int {
        return menuData.count
    }

    func tableView(
        _ tableView: UITableView,
        heightForHeaderInSection section: Int
    ) -> CGFloat {
        if isRedesignEnabled {
            guard section != 0 else { return 0 }
            return section == 1 ? UX.topPadding : UX.distanceBetweenSections
        }
        return section == 0 ? UX.topPadding : UX.distanceBetweenSections
    }

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        if isRedesignEnabled, section == 0 { return 0 }
        return menuData[section].options.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: MenuCell.cellIdentifier,
            for: indexPath
        ) as? MenuCell else {
            return UITableViewCell()
        }

        if isRedesignEnabled, indexPath.section == 0 { return UITableViewCell() }
        cell.configureCellWith(model: menuData[indexPath.section].options[indexPath.row])
        if let theme { cell.applyTheme(theme: theme) }
        return cell
    }

    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: false)

        if isRedesignEnabled, indexPath.section == 0 { return }
        if let action = menuData[indexPath.section].options[indexPath.row].action {
            action()
        }
    }

    func tableView(
        _ tableView: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView? {
        if isRedesignEnabled, section == 1 {
            return clearBackgroundHeaderView()
        } else if !isRedesignEnabled, section == 0 {
            return clearBackgroundHeaderView()
        }
        return nil
    }

    func reloadTableView(with data: [MenuSection]) {
        menuData = data
        tableView.reloadData()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= UX.topPadding {
            updateHeaderLineView?(false)
        } else {
            updateHeaderLineView?(true)
        }
    }

    private func clearBackgroundHeaderView() -> UIView {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        return headerView
    }

    // MARK: - Theme Applicable
    func applyTheme(theme: Theme) {
        self.theme = theme
        backgroundColor = .clear
        tableView.backgroundColor = .clear
        tableView.separatorColor = theme.colors.borderPrimary
    }
}
