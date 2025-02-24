// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

protocol SuggestionViewControllerDelegate: AnyObject {
    func tapOnSuggestion(term: String)
}

class SuggestionViewController: UIViewController, UITableViewDelegate {
    private var tableView: UITableView
    private var dataSource: SuggestionDataSource?
    private weak var delegate: SuggestionViewControllerDelegate?

    init() {
        self.tableView = UITableView(frame: .zero, style: .grouped)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()

        // Showing app logo when no search is visible
        tableView.isHidden = true
    }

    private func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // this ensures the table view header is removed and not shown
        tableView.tableHeaderView = UIView(frame: CGRect(origin: .zero,
                                                         size: CGSize(width: 0, height: CGFloat.leastNormalMagnitude)))
        tableView.delegate = self
        tableView.register(SuggestionCell.self, forCellReuseIdentifier: SuggestionCell.identifier)
    }

    func configure(dataSource: SuggestionDataSource,
                   delegate: SuggestionViewControllerDelegate?) {
        self.dataSource = dataSource
        tableView.dataSource = dataSource
        self.delegate = delegate
    }

    func updateUI(for suggestions: [String]) {
        tableView.isHidden = suggestions.isEmpty
        dataSource?.suggestions = suggestions
        tableView.reloadData()
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let term = dataSource?.suggestions[indexPath.row] else { return }
        delegate?.tapOnSuggestion(term: term)
    }
}
