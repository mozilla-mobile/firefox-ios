/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Core
import UIKit

final class Markets {
    static private (set) var all: [Market] = {
        return (try? JSONDecoder().decode([Market].self, from: Data(contentsOf: Bundle.main.url(forResource: "markets", withExtension: "json")!))) ?? []
    } ()

    static var current: String? {
        Markets.all.first { User.shared.marketCode == $0.id }.map {
            $0.name
        }
    }
}

final class MarketsController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private weak var table: UITableView!
    private let identifier = "market"

    required init?(coder: NSCoder) { nil }
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.theme.ecosia.primaryBackground
        navigationItem.title = .localized(.searchRegion)

        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.tintColor = UIColor.theme.ecosia.primaryBrand
        table.delegate = self
        table.dataSource = self
        table.backgroundColor = .clear
        view.addSubview(table)
        self.table = table
        
        table.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        table.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        table.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        table.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Markets.all.firstIndex { User.shared.marketCode == $0.id }.map {
            table.scrollToRow(at: .init(row: $0, section: 0), at: .middle, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Markets.all.count
    }

    func tableView(_ : UITableView, cellForRowAt: IndexPath) -> UITableViewCell {
        let cell = table.dequeueReusableCell(withIdentifier: identifier) ?? ThemedTableViewCell(style: .default, reuseIdentifier: identifier)
        cell.textLabel!.text = Markets.all[cellForRowAt.row].name
        cell.textLabel!.textColor = UIColor.theme.tableView.rowText
        cell.accessoryType = User.shared.marketCode == Markets.all[cellForRowAt.row].id ? .checkmark : .none
        return cell
    }
    
    func tableView(_: UITableView, didSelectRowAt: IndexPath) {
        guard Markets.all[didSelectRowAt.row].id != User.shared.marketCode else { return }
        User.shared.marketCode = Markets.all[didSelectRowAt.row].id
        table.reloadData()
        
        // TODO Analytics.shared.market(User.shared.marketCode.rawValue)
        Goodall.shared.refresh()
    }
}
