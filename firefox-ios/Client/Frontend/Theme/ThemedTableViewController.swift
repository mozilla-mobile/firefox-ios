// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Common

class ThemedTableViewController: UITableViewController, Themeable, InjectedThemeUUIDIdentifiable {
    var themeManager: ThemeManager
    @objc var notificationCenter: NotificationProtocol
    var themeObserver: NSObjectProtocol?
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { return windowUUID }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(style: UITableView.Style = .grouped,
         windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(style: style)
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        return dequeueCellFor(indexPath: indexPath)
    }

    /// Dequeues a ThemedTableViewCell for the provided IndexPath.
    /// 
    /// This method could be overridden by subclasses, if subclasses of ThemedTableViewCell are needed to be dequeued.
    /// In order to deque subclasses of ThemedTableViewCell they must be registered in the table view.
    func dequeueCellFor(indexPath: IndexPath) -> ThemedTableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ThemedTableViewCell.cellIdentifier,
            for: indexPath
        ) as? ThemedTableViewCell
        else {
            return ThemedTableViewCell()
        }
        return cell
    }

    override func tableView(
        _ tableView: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier
        ) as? ThemedTableSectionHeaderFooterView
        else { return nil }
        headerView.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        return headerView
    }

    override func tableView(
        _ tableView: UITableView,
        viewForFooterInSection section: Int
    ) -> UIView? {
        guard let footerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier
        ) as? ThemedTableSectionHeaderFooterView
        else { return nil }
        footerView.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        return footerView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(cellType: ThemedTableViewCell.self)
        tableView.register(cellType: ThemedCenteredTableViewCell.self)
        applyTheme()
        listenForThemeChange(view)
    }

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        tableView.separatorColor = theme.colors.borderPrimary
        tableView.backgroundColor = theme.colors.layer1
        tableView.reloadData()
    }
}

class ThemedHeaderFooterViewBordersHelper: ThemeApplicable {
    enum BorderLocation {
        case top
        case bottom
    }

    private lazy var topBorder: UIView = .build()

    private lazy var bottomBorder: UIView = .build()

    func showBorder(for location: BorderLocation, _ show: Bool) {
        switch location {
        case .top:
            topBorder.isHidden = !show
        case .bottom:
            bottomBorder.isHidden = !show
        }
    }

    func initBorders(view: UIView) {
        view.addSubview(topBorder)
        view.addSubview(bottomBorder)

        NSLayoutConstraint.activate([
            topBorder.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBorder.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBorder.topAnchor.constraint(equalTo: view.topAnchor),
            topBorder.heightAnchor.constraint(equalToConstant: 0.25),
            bottomBorder.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBorder.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBorder.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBorder.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    func applyTheme(theme: Theme) {
        topBorder.backgroundColor = theme.colors.borderPrimary
        bottomBorder.backgroundColor = theme.colors.borderPrimary
    }
}
