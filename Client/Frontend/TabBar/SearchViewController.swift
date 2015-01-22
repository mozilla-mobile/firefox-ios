/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

private let ReuseIdentifier = "cell"
private let SuggestionsLimitCount = 3

// A delegate to support clicking on rows in the view controller
// This needs to be accessible to objc for UIViewControllers to call it
@objc
protocol UrlViewControllerDelegate: class {
    func didClickUrl(url: NSURL)
}

class TableViewData {
    let text: String
    let description: String?
    let icon: UIImage?
    let url: NSURL?

    init(text: String, description: String?, icon: UIImage?, url: NSURL?) {
        self.text = text
        self.description = description
        self.icon = icon
        self.url = url
    }
}

class SearchViewController: UIViewController {
    weak var delegate: UrlViewControllerDelegate?
    private var tableView = UITableView()
    private var results = MultiCursor()
    private var searchSuggestions = [String]()

    private func SearchEngineToView(obj: Any) -> Any? {
        if let engine = obj as? OpenSearchEngine {
            return TableViewData(text: engine.shortName,
                description: engine.description,
                icon: engine.image,
                url: engine.searchURLForQuery(self.searchQuery))
        }
        return nil
    }

    private func SuggestionToView(engine: OpenSearchEngine) -> (Any) -> Any? {
        return { obj -> Any? in
            if let suggestion = obj as? String {
                return TableViewData(text: suggestion,
                    description: nil,
                    icon: nil,
                    url: engine.searchURLForQuery(self.searchQuery))
            }
            return nil
        }
    }

    var searchEngines: SearchEngines? {
        didSet {
            results.clearPendingRequests()

            if let searchEngines = searchEngines {
                // Show suggestions at the top of the list
                // TODO: If suggestions are disabled, the suggest client should still show the default search engine on top
                let defaultEngine = searchEngines.defaultEngine
                let suggestions = SearchSuggestClient<String>(searchEngine: defaultEngine, factory: SuggestionToView(defaultEngine))
                suggestions.maxResults = SuggestionsLimitCount
                results.addCursor(suggestions, index: 0)

                // At the bottom show sorted search engines
                // Sort the list so the default is on top.
                // TODO: The sgugestions client can handle showing thie row on top. We should just remove it from this list
                //       SearchViewController is the only one that needs to know about this detail.
                let sortedEngines = searchEngines.list.sorted { engine, _ in engine === searchEngines.defaultEngine }
                results.addCursor(ArrayCursor(data: sortedEngines, factory: SearchEngineToView))
            } else {
                results.removeAll()
            }

            querySuggestClient()

            // Reload the tableView to show the new list of search engines.
            tableView.reloadData()
        }
    }

    var searchQuery: String = "" {
        didSet {
            querySuggestClient()

            // Reload the tableView to show the updated text in each engine.
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

    private func querySuggestClient() {
        results.clearPendingRequests()
        results.query(searchQuery) {
            self.tableView.reloadData()
        }
    }
}

extension SearchViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        if let data = results[indexPath.item] {
            //if let presenter = data as? Presenter {
            //    cell = presenter(tableView)
            //} else
            if let v = data as? TableViewData {
                cell = tableView.dequeueReusableCellWithIdentifier(ReuseIdentifier, forIndexPath: indexPath) as SearchTableViewCell
                cell.textLabel?.text = v.text
                cell.detailTextLabel?.text = v.description
                cell.imageView?.image = v.icon
                 cell.isAccessibilityElement = false
            } else {
                cell = tableView.dequeueReusableCellWithIdentifier(ReuseIdentifier, forIndexPath: indexPath) as SearchTableViewCell
                cell.textLabel?.text = "\(data)"
                cell.detailTextLabel?.text = nil
                cell.imageView?.image = nil
            }
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier(ReuseIdentifier, forIndexPath: indexPath) as SearchTableViewCell
            cell.textLabel?.text = "No data?"
            cell.detailTextLabel?.text = nil
            cell.imageView?.image = nil
        }

        return cell
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var url: NSURL?
        if let data = results[indexPath.row] {
            var url: NSURL? = nil
            if let v = data as? TableViewData {
                url = v.url
            } else if let d = data as? String {
                // XXX - This should fixup the url
                url = NSURL(string: d)
            } else {
                println("Not sure how to open \(data)")
            }

            if let url = url {
                delegate?.didClickUrl(url)
            }
        }
    }
}

private class SearchTableViewCell: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        // ignore the style argument, use our own to override
        super.init(style: UITableViewCellStyle.Subtitle, reuseIdentifier: reuseIdentifier)
        textLabel?.font = UIFont(name: "FiraSans-SemiBold", size: 13)
        textLabel?.textColor = UIColor.darkGrayColor()
        indentationWidth = 20

        // Make the row separators span the width of the entire table.
        layoutMargins = UIEdgeInsetsZero

        detailTextLabel?.textColor = UIColor.lightGrayColor()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView?.bounds = CGRectMake(0, 0, 24, 24)
    }
}
