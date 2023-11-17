/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Core
import UIKit

final class Markets {
    static private (set) var all: [Market] = {
        return (try? JSONDecoder().decode([Market].self, from: Data(contentsOf: Bundle.main.url(forResource: "markets", withExtension: "json")!)))?.sorted(by: { $0.displayName.compare($1.displayName) == .orderedAscending })  ?? []
    } ()

    static var current: String? {
        Markets.all.first { User.shared.marketCode == $0.value }.map {
            $0.displayName
        }
    }
}

extension Market {
    var displayName: String {
        let comps = value.rawValue.components(separatedBy: "-")
        let country = Locale.current.localizedString(forRegionCode: comps.last ?? "") ?? .localized(label)

        if languageInLabel, let lan = comps.first, let language = Locale.current.localizedString(forLanguageCode: lan) {
            return "\(country) (\(language))"
        } else {
            return country
        }
    }
}

final class MarketsController: ThemedTableViewController {
    private let identifier = "market"

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = .localized(.searchRegion)
        navigationItem.largeTitleDisplayMode = .never
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Markets.all.firstIndex { User.shared.marketCode == $0.value }.map {
            tableView.scrollToRow(at: .init(row: $0, section: 0), at: .middle, animated: true)
        }
    }

    override func tableView(_: UITableView, numberOfRowsInSection: Int) -> Int {
        Markets.all.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? ThemedTableViewCell(style: .default, reuseIdentifier: identifier)

        let market = Markets.all[cellForRowAt.row]
        cell.textLabel?.text = market.displayName
        cell.accessoryType = User.shared.marketCode == Markets.all[cellForRowAt.row].value ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt: IndexPath) {
        guard Markets.all[didSelectRowAt.row].value != User.shared.marketCode else { return }
        User.shared.marketCode = Markets.all[didSelectRowAt.row].value
        tableView.reloadData()
        Analytics.shared.navigationChangeMarket(User.shared.marketCode.rawValue)
    }

    override func applyTheme() {
        super.applyTheme()
        view.backgroundColor = UIColor.legacyTheme.tableView.headerBackground
    }
}
