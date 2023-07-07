// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import ComponentLibrary

class RootViewController: UIViewController, UITableViewDelegate {
    // MARK: - Properties
    private let dataSource = ComponentDataSource()

    private lazy var tableView: UITableView = .build { tableView in
        tableView.register(ComponentButtonCell.self, forCellReuseIdentifier: ComponentButtonCell.cellIdentifier)
        tableView.delegate = self
        tableView.separatorStyle = .none
    }

    // MARK: - Init
    init() {
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .white
        tableView.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    private func setupTableView() {
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        tableView.dataSource = dataSource
        tableView.reloadData()
    }
}

class ComponentDataSource: NSObject, UITableViewDataSource {
    private var componentData = ComponentData()

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return componentData.data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ComponentButtonCell.cellIdentifier)
        guard let cell = cell as? ComponentButtonCell else { return UITableViewCell() }
        cell.setup(componentData.data[indexPath.row])
        return cell
    }
}
