/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Core
import UIKit

private let items: [(AdultFilter, String)] = [
    (.strict, .localized(.strict)),
    (.moderate, .localized(.moderate)),
    (.off, .localized(.off))]

final class FilterController: UIViewController, UITableViewDataSource, UITableViewDelegate, NotificationThemeable {
    private weak var table: UITableView!

    private let identifier = "filter"
    static var current: String? {
        items.first(where: { $0.0 == User.shared.adultFilter }).map { $0.1 }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = .localized(.safeSearch)
        navigationItem.largeTitleDisplayMode = .never
        
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.tableFooterView = .init()

        view.addSubview(table)
        self.table = table
        
        table.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        table.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        table.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        table.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true

        applyTheme()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ : UITableView, cellForRowAt: IndexPath) -> UITableViewCell {
        let cell = table.dequeueReusableCell(withIdentifier: identifier) ?? ThemedTableViewCell(style: .default, reuseIdentifier: identifier)
        cell.textLabel!.text = items[cellForRowAt.row].1
        cell.accessoryType = User.shared.adultFilter == items[cellForRowAt.row].0 ? .checkmark : .none
        return cell
    }
    
    func tableView(_: UITableView, didSelectRowAt: IndexPath) {
        User.shared.adultFilter = items[didSelectRowAt.row].0
        table.reloadData()
    }

    func applyTheme() {
        table.visibleCells.forEach {
            ($0 as? NotificationThemeable)?.applyTheme()
        }

        view.backgroundColor = UIColor.theme.tableView.headerBackground
        table.tintColor = UIColor.theme.ecosia.primaryBrand
        table.separatorColor = UIColor.theme.tableView.separator
        table.backgroundColor = UIColor.theme.tableView.headerBackground
    }
}
