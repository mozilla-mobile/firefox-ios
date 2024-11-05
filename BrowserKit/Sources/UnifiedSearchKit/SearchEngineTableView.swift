// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common
import MenuKit

public final class SearchEngineTableView: UIView,
                             UITableViewDelegate,
                             UITableViewDataSource, ThemeApplicable {
    private struct UX {
        static let topPadding: CGFloat = 10
    }

    private var tableView: UITableView
    private var menuData: [MenuSection] // FIXME will be different later...
    private var theme: Theme?

    override init(frame: CGRect) {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        menuData = []
        super.init(frame: .zero)
        setupView()
    }

    required public init?(coder: NSCoder) {
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

    // MARK: - UITableView Methods
    public func numberOfSections(in tableView: UITableView) -> Int {
        return menuData.count
    }

    public func tableView(
        _ tableView: UITableView,
        heightForHeaderInSection section: Int
    ) -> CGFloat {
        return section == 0 ? UX.topPadding : UITableView.automaticDimension
    }

    public func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return menuData[section].options.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MenuCell.cellIdentifier,
            for: indexPath
        ) as! MenuCell

        cell.configureCellWith(model: menuData[indexPath.section].options[indexPath.row])
        if let theme { cell.applyTheme(theme: theme) }
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        if let action = menuData[indexPath.section].options[indexPath.row].action {
            action()
        }
    }

//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        if section == 0 {
//            let headerView = UIView()
//            headerView.backgroundColor = .clear
//            return headerView
//        }
//        return nil
//    }

    public func reloadTableView(with data: [MenuSection]) {
        menuData = data
        tableView.reloadData()
    }

    // MARK: - Theme Applicable
    public func applyTheme(theme: Theme) {
        self.theme = theme
        backgroundColor = .clear
        tableView.backgroundColor = .clear
        tableView.separatorColor = theme.colors.borderPrimary
    }
}
