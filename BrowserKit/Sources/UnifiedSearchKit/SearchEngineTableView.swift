// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common
import MenuKit

// FXIOS-10189 This class will be refactored into a generic UITableView solution later. For now, it is largely a clone of
// MenuKit's work. Eventually both this target and the MenuKit target will leverage a common reusable tableView component.
public final class SearchEngineTableView: UIView,
                             UITableViewDelegate,
                             UITableViewDataSource,
                             ThemeApplicable {
    private struct UX {
        static let topPadding: CGFloat = 10
    }

    private var tableView: UITableView
    private var searchEngineData: [SearchEngineSection]
    private var theme: Theme?

    override init(frame: CGRect) {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        searchEngineData = []
        super.init(frame: .zero)
        setupView()
    }

    public required init?(coder: NSCoder) {
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
            SearchEngineCell.self,
            forCellReuseIdentifier: SearchEngineCell.cellIdentifier
        )
    }

    // MARK: - UITableView Methods
    public func numberOfSections(in tableView: UITableView) -> Int {
        return searchEngineData.count
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? UX.topPadding : UITableView.automaticDimension
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchEngineData[section].options.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: SearchEngineCell.cellIdentifier,
            for: indexPath
        ) as! SearchEngineCell

        cell.configureCellWith(model: searchEngineData[indexPath.section].options[indexPath.row])
        if let theme { cell.applyTheme(theme: theme) }
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        if let action = searchEngineData[indexPath.section].options[indexPath.row].action {
            action()
        }
    }

    public func reloadTableView(with data: [SearchEngineSection]) {
        searchEngineData = data
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
