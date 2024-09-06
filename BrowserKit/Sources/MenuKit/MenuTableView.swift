// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

public class MenuTableView: UIView, UITableViewDataSource, UITableViewDelegate {
    // Declare the table view as a property of the container view
    private let tableView = UITableView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .systemPink
        setupTableView()
    }

    // Function to set up the table view
    private func setupTableView() {
        // Add the table view to the container view
        self.addSubview(tableView)

        // Set up the table view's frame or constraints
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: self.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])

        // Register the generic cell for reuse
        tableView.register(
            MenuTableViewCell.self,
            forCellReuseIdentifier: MenuTableViewCell.cellIdentifier
        )

        // Set the data source and delegate to the current view
        tableView.dataSource = self
        tableView.delegate = self
    }

    // MARK: - UITableViewDataSource Methods

    // Return the number of rows in the table view
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // For this example, we'll just return 10 rows
        return 10
    }

    // Create and configure cells for the table view
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue a reusable cell of the specified type
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MenuTableViewCell.cellIdentifier,
            for: indexPath
        ) as! MenuTableViewCell

        // Customize the cell content for the specific row
        cell.textLabel?.text = "Row \(indexPath.row + 1)"

        return cell
    }

    // MARK: - UITableViewDelegate Methods

    // Handle row selection (optional)
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Selected row at index: \(indexPath.row)")
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
