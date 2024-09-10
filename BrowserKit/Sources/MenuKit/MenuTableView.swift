// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

class MenuTableView: UIView, UITableViewDataSource, UITableViewDelegate {
    private let tableView: UITableView
    private var menuData: [MenuSection] = []

    override init(frame: CGRect) {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        setupTableView()
    }

    private func setupTableView() {
        backgroundColor = .clear
        tableView.backgroundColor = .clear
        self.addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: self.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])

        tableView.register(
            MenuCell.self,
            forCellReuseIdentifier: MenuCell.cellIdentifier
        )

        tableView.dataSource = self
        tableView.delegate = self
    }

    func updateDataSource(_ newDataSource: [MenuSection]) {
        self.menuData = newDataSource
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource Methods
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

        return cell
    }

    // MARK: - UITableViewDelegate Methods
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        guard let action = menuData[indexPath.section].options[indexPath.row].action else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        action()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
