// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common

public protocol MenuTableViewDataDelegate: AnyObject {
    func reloadTableView(with data: [MenuSection])
}

class MenuTableView: UIView,
                     UITableViewDelegate,
                     UITableViewDataSource, ThemeApplicable {
    private var tableView: UITableView
    private var menuData: [MenuSection]
    private var theme: Theme?

    public var updateHeaderLineView: ((_ scrollViewOffset: CGFloat) -> Void)?

    override init(frame: CGRect) {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
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

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return menuData.count
    }

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return menuData[section].options.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MenuCell.cellIdentifier,
            for: indexPath
        ) as! MenuCell

        cell.configureCellWith(model: menuData[indexPath.section].options[indexPath.row])
        if let theme { cell.applyTheme(theme: theme) }
        return cell
    }

    // MARK: - UITableViewDelegate Methods
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: false)

        if let action = menuData[indexPath.section].options[indexPath.row].action {
            action()
        }
    }

    func reloadTableView(with data: [MenuSection]) {
        menuData = data
        tableView.reloadData()
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateHeaderLineView?(scrollView.contentOffset.y)
    }

    // MARK: - Theme Applicable
    func applyTheme(theme: Theme) {
        self.theme = theme
        backgroundColor = .clear
        tableView.backgroundColor = .clear
    }
}
