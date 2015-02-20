/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage

private let SuggestionsLimitCount = 3

private enum SearchListSection: Int {
    case SearchSuggestions
    case BookmarksAndHistory
    case Search
}

class SearchViewController: SiteTableViewController {
    private var sortedEngines = [OpenSearchEngine]()
    private var suggestClient: SearchSuggestClient?
    private var searchSuggestions = [String]()

    var searchEngines: SearchEngines? {
        didSet {
            suggestClient?.cancelPendingRequest()

            if let searchEngines = searchEngines {
                // Show the default search engine first.
                sortedEngines = searchEngines.list.sorted { engine, _ in engine === searchEngines.defaultEngine }
                suggestClient = SearchSuggestClient(searchEngine: searchEngines.defaultEngine)
            } else {
                sortedEngines = []
                suggestClient = nil
            }

            querySuggestClient()

            // Reload the tableView to show the new list of search engines.
            tableView.reloadData()
        }
    }

    var searchQuery: String = "" {
        didSet {
            // Reload the tableView to show the updated text in each engine.
            reloadData()
        }
    }

    override func reloadData() {
        querySuggestClient()
        queryHistoryClient()
        tableView.reloadData()
    }

    private func querySuggestClient() {
        suggestClient?.cancelPendingRequest()

        if searchQuery.isEmpty {
            searchSuggestions = []
            return
        }

        suggestClient?.query(searchQuery, callback: { suggestions, error in
            if let error = error {
                let isSuggestClientError = error.domain == SearchSuggestClientErrorDomain

                switch error.code {
                case NSURLErrorCancelled where error.domain == NSURLErrorDomain:
                    // Request was cancelled. Do nothing.
                    break
                case SearchSuggestClientErrorInvalidEngine where isSuggestClientError:
                    // Engine does not support search suggestions. Do nothing.
                    break
                case SearchSuggestClientErrorInvalidResponse where isSuggestClientError:
                    println("Error: Invalid search suggestion data")
                default:
                    println("Error: \(error.description)")
                }

                self.searchSuggestions = []
            } else {
                self.searchSuggestions = suggestions!
                if self.searchSuggestions.count > SuggestionsLimitCount {
                    self.searchSuggestions.removeRange(SuggestionsLimitCount..<self.searchSuggestions.count)
                }
            }

            // Reload the tableView to show the new list of search suggestions.
            self.tableView.reloadData()
        })
    }

    private func queryHistoryClient() {
        if searchQuery.isEmpty {
            data = Cursor(status: .Success, msg: "Empty query")
            return
        }

        let options = QueryOptions()
        options.sort = .LastVisit
        options.filter = searchQuery

        profile.history.get(options, complete: { (data: Cursor) -> Void in
            self.data = data
            if data.status != .Success {
                println("Err: \(data.statusMessage)")
            }
            self.tableView.reloadData()
        })
    }
}

extension SearchViewController: UITableViewDataSource {
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)

        if let currentSection = SearchListSection(rawValue: indexPath.section) {
            switch currentSection {
            case .SearchSuggestions:
                cell.textLabel?.text = searchSuggestions[indexPath.row]
                cell.detailTextLabel?.text = nil
                cell.imageView?.image = nil
                cell.isAccessibilityElement = false
                cell.accessibilityLabel = nil
            case .BookmarksAndHistory:
                if let site = data[indexPath.row] as? Site {
                    cell.textLabel?.text = site.title
                    cell.detailTextLabel?.text = site.url
                    if let img = site.icon? {
                        let imgUrl = NSURL(string: img.url)
                        cell.imageView?.sd_setImageWithURL(imgUrl, placeholderImage: self.profile.favicons.defaultIcon)
                    } else {
                        cell.imageView?.image = self.profile.favicons.defaultIcon
                    }
                    cell.isAccessibilityElement = false
                    cell.accessibilityLabel = nil
                }
            case .Search:
                let searchEngine = sortedEngines[indexPath.row]
                cell.textLabel?.text = searchQuery
                cell.detailTextLabel?.text = nil
                cell.imageView?.image = searchEngine.image
                cell.isAccessibilityElement = true
                cell.accessibilityLabel = NSString(format: NSLocalizedString("%@ search for %@", comment: "E.g. \"Google search for Mars\". Please keep the first \"%@\" (which contains the search engine name) as close to the beginning of the translated phrase as possible (it is best to have it as the very first word). This is because the phrase is an accessibility label and VoiceOver users need to hear the search engine name first as that is the key information in the whole phrase (they know the search term because they typed it and from previous rows of the table)."), searchEngine.shortName, searchQuery)
            }
        }

        // Make the row separators span the width of the entire table.
        cell.layoutMargins = UIEdgeInsetsZero

        return cell
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let currentSection = SearchListSection(rawValue: section) {
            switch(currentSection) {
            case .SearchSuggestions:
                return searchSuggestions.count
            case .Search:
                return sortedEngines.count
            case .BookmarksAndHistory:
                return data.count
            }
        }
        return 0
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
}

extension SearchViewController: UITableViewDelegate {
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var url: NSURL?
        if let currentSection = SearchListSection(rawValue: indexPath.section) {
            switch currentSection {
            case .SearchSuggestions:
                let suggestion = searchSuggestions[indexPath.row]

                // Assume that only the default search engine can provide search suggestions.
                url = searchEngines?.defaultEngine.searchURLForQuery(suggestion)
            case .BookmarksAndHistory:
                if let site = data[indexPath.row] as? Site {
                    url = NSURL(string: site.url)
                }
            case .Search:
                let engine = sortedEngines[indexPath.row - searchSuggestions.count]
                url = engine.searchURLForQuery(searchQuery)
            }
        }

        if let url = url {
            delegate?.homePanel(didSubmitURL: url)
        }
    }
}
