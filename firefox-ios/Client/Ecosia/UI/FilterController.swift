// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Ecosia
import UIKit
import Common

private let items: [(AdultFilter, String)] = [
    (.strict, .localized(.strict)),
    (.moderate, .localized(.moderate)),
    (.off, .localized(.off))]

final class FilterController: ThemedTableViewController {

    private let identifier = "filter"
    static var current: String? {
        items.first(where: { $0.0 == User.shared.adultFilter }).map { $0.1 }
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = .localized(.safeSearch)
        navigationItem.largeTitleDisplayMode = .never

        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? ThemedTableViewCell(style: .default, reuseIdentifier: identifier)
        cell.textLabel!.text = items[cellForRowAt.row].1
        cell.accessoryType = User.shared.adultFilter == items[cellForRowAt.row].0 ? .checkmark : .none
        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt: IndexPath) {
        User.shared.adultFilter = items[didSelectRowAt.row].0
        tableView.reloadData()
    }

    override func applyTheme() {
        super.applyTheme()
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        tableView.visibleCells.forEach {
            ($0 as? Themeable)?.applyTheme()
            ($0 as? ThemeApplicable)?.applyTheme(theme: theme)
        }

        view.backgroundColor = theme.colors.ecosia.backgroundPrimaryDecorative
        tableView.tintColor = theme.colors.ecosia.brandPrimary
        tableView.separatorColor = theme.colors.ecosia.borderDecorative
        tableView.backgroundColor = theme.colors.ecosia.backgroundPrimaryDecorative
    }
}
