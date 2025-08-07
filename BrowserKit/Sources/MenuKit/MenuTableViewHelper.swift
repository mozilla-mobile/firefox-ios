// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class MenuTableViewHelper: NSObject, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    private struct UX {
        static let topPadding: CGFloat = 24
        static let menuSiteTopPadding: CGFloat = 12
        static let topPaddingWithBanner: CGFloat = 8
        static let distanceBetweenSections: CGFloat = 16
    }

    private weak var tableView: UITableView?
    private var menuData: [MenuSection] = []
    private var theme: Theme?
    private var isBannerVisible = false
    private var isHomepage = false

    init(tableView: UITableView) {
        self.tableView = tableView
        super.init()
        self.tableView?.delegate = self
        self.tableView?.dataSource = self
    }

    func updateData(_ data: [MenuSection], theme: Theme?, isBannerVisible: Bool) {
        self.menuData = data
        self.theme = theme
        self.isBannerVisible = isBannerVisible
    }

    func reload() {
        tableView?.reloadData()
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return menuData.count
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
                withIdentifier: MenuSquaresViewContentCell.cellIdentifier,
                for: indexPath) as? MenuSquaresViewContentCell else {
                return UITableViewCell()
            }
            if let theme { cell.applyTheme(theme: theme) }
            cell.reloadData(with: menuData, and: menuData[indexPath.section].groupA11yLabel)
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
                let numberOfRows = tableView.numberOfRows(inSection: indexPath.section)
                let isFirst = indexPath.row == 0
                let isLast = indexPath.row == numberOfRows - 1
                cell.configureCellWith(model: rowOption, theme: theme, isFirstCell: isFirst, isLastCell: isLast)
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
            withIdentifier: MenuCell.cellIdentifier,
            for: indexPath
        ) as? MenuCell else {
            return UITableViewCell()
        }
        if let theme {
            let numberOfRows = tableView.numberOfRows(inSection: indexPath.section)
            let isFirst = indexPath.row == 0
            let isLast = indexPath.row == numberOfRows - 1
            cell.configureCellWith(model: rowOption, theme: theme, isFirstCell: isFirst, isLastCell: isLast)
            cell.applyTheme(theme: theme)
        }
        return cell
    }

    // MARK: - UITableViewDelegate
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: false)
        let section = menuData[indexPath.section]

        // We handle the actions for horizontalTabs, in MenuSquaresViewContentCell
        if !section.isHorizontalTabsSection {
            if let action = section.options[indexPath.row].action {
                action()
            }
        }
    }

    func tableView(
        _ tableView: UITableView,
        heightForHeaderInSection section: Int
    ) -> CGFloat {
        if let menuSection = menuData.first(where: { $0.isHomepage }), menuSection.isHomepage {
            self.isHomepage = true
            let topPadding = isBannerVisible ? UX.topPaddingWithBanner : UX.topPadding
            return section == 0 ? topPadding : UX.distanceBetweenSections
        }
        return section == 0 ? UX.menuSiteTopPadding : UX.distanceBetweenSections
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

    // MARK: - UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isHomepage, !UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory {
            scrollView.contentOffset = .zero
            scrollView.showsVerticalScrollIndicator = false
        }
    }
}
