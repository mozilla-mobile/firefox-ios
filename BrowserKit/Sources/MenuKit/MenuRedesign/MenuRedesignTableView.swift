// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common

final class MenuRedesignTableView: UIView,
                           UITableViewDelegate,
                           UITableViewDataSource,
                           ThemeApplicable {
    private struct UX {
        static let topPadding: CGFloat = 12
        static let tableViewMargin: CGFloat = 16
        static let distanceBetweenSections: CGFloat = 16

        // Menu Redesign horizontal squares cells sizes
        static let iconSize: CGFloat = 24
        static let contentViewSpacing: CGFloat = 4
        static let contentViewTopMargin: CGFloat = 12
        static let contentViewBottomMargin: CGFloat = 8
    }

    private var tableView: UITableView
    private var menuData: [MenuSection]
    private var theme: Theme?

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
        tableView.register(MenuRedesignCell.self, forCellReuseIdentifier: MenuRedesignCell.cellIdentifier)
        tableView.register(MenuInfoCell.self, forCellReuseIdentifier: MenuInfoCell.cellIdentifier)
        tableView.register(MenuAccountCell.self, forCellReuseIdentifier: MenuAccountCell.cellIdentifier)
        tableView.register(MenuCollectionViewContainerCell.self,
                           forCellReuseIdentifier: MenuCollectionViewContainerCell.cellIdentifier)
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
        return section == 0 ? UX.topPadding : UX.distanceBetweenSections
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if menuData[indexPath.section].isHorizontalTabsSection {
            let label = UILabel()
            label.font = FXFontStyles.Regular.caption1.scaledFont()
            label.text = menuData[indexPath.section].options.first?.title
            label.sizeToFit()
            let textHeight = label.frame.height
            let iconHeight: CGFloat = UX.iconSize
            let spacing: CGFloat = UX.contentViewSpacing
            let topMargin: CGFloat = UX.contentViewTopMargin
            let bottomMargin: CGFloat = UX.contentViewBottomMargin
            return topMargin + iconHeight + spacing + textHeight + bottomMargin
        }
        return UITableView.automaticDimension
    }

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        if menuData[section].isHorizontalTabsSection {
            return 1
        } else if let isExpanded = menuData[section].isExpanded, isExpanded {
            return menuData[section].options.count
        } else {
            return menuData[section].options.count(where: { !$0.isOptional })
        }
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        if menuData[indexPath.section].isHorizontalTabsSection {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: MenuCollectionViewContainerCell.cellIdentifier,
                for: indexPath) as? MenuCollectionViewContainerCell else {
                return UITableViewCell()
            }
            cell.reloadCollectionView(with: menuData)
            if let theme { cell.applyTheme(theme: theme) }
            return cell
        }

        let rowOption = menuData[indexPath.section].options[indexPath.row]

        if rowOption.iconImage != nil || rowOption.needsReAuth != nil {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: MenuAccountCell.cellIdentifier,
                for: indexPath
            ) as? MenuAccountCell else {
                return UITableViewCell()
            }
            if let theme {
                cell.configureCellWith(model: rowOption, theme: theme)
                cell.applyTheme(theme: theme)
            }
            return cell
        }

        if rowOption.infoTitle != nil {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: MenuInfoCell.cellIdentifier,
                for: indexPath
            ) as? MenuInfoCell else {
                return UITableViewCell()
            }
            if let theme {
                cell.configureCellWith(model: rowOption)
                cell.applyTheme(theme: theme)
            }
            return cell
        }

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: MenuRedesignCell.cellIdentifier,
            for: indexPath
        ) as? MenuRedesignCell else {
            return UITableViewCell()
        }
        if let theme {
            cell.configureCellWith(model: rowOption, theme: theme)
            cell.applyTheme(theme: theme)
        }
        return cell
    }

    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: false)

        if let action = menuData[indexPath.section].options[indexPath.row].action {
            action()
        }
    }

    func tableView(
        _ tableView: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView? {
        if section == 0 {
            let headerView = UIView()
            headerView.backgroundColor = .clear
            return headerView
        }
        return nil
    }

    func reloadTableView(with data: [MenuSection]) {
        // We ignore first section because it is handled in MenuCollectionViewContainerCell
        if let firstSection = data.first, firstSection.isHorizontalTabsSection {
            tableView.showsVerticalScrollIndicator = false
            menuData = data
            menuData.removeAll(where: { $0.isHorizontalTabsSection })
        } else {
            menuData = data
        }
        tableView.reloadData()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= UX.topPadding {
            updateHeaderLineView?(false)
        } else {
            updateHeaderLineView?(true)
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
