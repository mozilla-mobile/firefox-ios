/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

private let ReuseIdentifier = "cell"

protocol SearchViewControllerDelegate: class {
    func didClickSearchResult(url: NSURL)
}

class SearchViewController: UIViewController {
    weak var delegate: SearchViewControllerDelegate?
    private var tableView = UITableView()
    private var sortedEngines = [OpenSearchEngine]()

    var searchEngines: SearchEngines? {
        didSet {
            if let searchEngines = searchEngines {
                // Show the default search engine first.
                sortedEngines = searchEngines.list.sorted { engine, _ in engine === searchEngines.defaultEngine }
            } else {
                sortedEngines = []
            }
            tableView.reloadData()
        }
    }

    var searchQuery: String = "" {
        didSet {
            tableView.reloadData()
        }
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init() {
        // The empty initializer of UIViewController creates the class twice (?!),
        // so override it here to avoid calling it.
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerClass(SearchTableViewCell.self, forCellReuseIdentifier: ReuseIdentifier)

        // Make the row separators span the width of the entire table.
        tableView.layoutMargins = UIEdgeInsetsZero
        tableView.separatorInset = UIEdgeInsetsZero

        view.addSubview(tableView)
        tableView.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
            return
        }
    }
}

extension SearchViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(ReuseIdentifier, forIndexPath: indexPath) as SearchTableViewCell
        let searchEngine = sortedEngines[indexPath.row]
        cell.textLabel?.text = searchQuery
        cell.imageView?.image = searchEngine.image

        // Make the row separators span the width of the entire table.
        cell.layoutMargins = UIEdgeInsetsZero

        return cell
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedEngines.count
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let engine = sortedEngines[indexPath.row]
        let url = engine.searchURLForQuery(searchQuery)
        if let url = url {
            delegate?.didClickSearchResult(url)
        }
    }
}

private class SearchTableViewCell: UITableViewCell {
    private override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView?.bounds = CGRectMake(0, 0, 24, 24)
    }
}