/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage

private let SuggestionsLimitCount = 3

// searchEngineScrollViewContent is the button container. It has a gray background color,
// so with insets applied to its buttons, the background becomes the button border.
private let EngineButtonInsets = UIEdgeInsetsMake(0.5, 0.5, 0.5, 0.5)

// TODO: This should use ToolbarHeight in BVC. Fix this when we create a shared theming file.
private let EngineButtonHeight: Float = 44
private let EngineButtonWidth = EngineButtonHeight * 1.5

private enum SearchListSection: Int {
    case SearchSuggestions
    case BookmarksAndHistory
}

protocol SearchViewControllerDelegate: class {
    func searchViewController(searchViewController: SearchViewController, didSelectURL url: NSURL)
}

class SearchViewController: SiteTableViewController, KeyboardHelperDelegate {
    var searchDelegate: SearchViewControllerDelegate?

    private var suggestClient: SearchSuggestClient?
    private var searchSuggestions = [String]()

    // Views for displaying the bottom scrollable search engine list. searchEngineScrollView is the
    // scrollable container; searchEngineScrollViewContent contains the actual set of search engine buttons.
    private let searchEngineScrollView = ButtonScrollView()
    private let searchEngineScrollViewContent = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        KeyboardHelper.defaultHelper.addDelegate(self)

        searchEngineScrollView.layer.backgroundColor = tableView.backgroundColor?.CGColor
        searchEngineScrollView.decelerationRate = UIScrollViewDecelerationRateFast
        view.addSubview(searchEngineScrollView)

        searchEngineScrollViewContent.layer.backgroundColor = tableView.separatorColor.CGColor
        searchEngineScrollView.addSubview(searchEngineScrollViewContent)

        tableView.snp_remakeConstraints { make in
            make.top.left.right.equalTo(self.view)
            make.bottom.equalTo(self.searchEngineScrollView.snp_top)
        }

        layoutSearchEngineScrollView()

        searchEngineScrollViewContent.snp_makeConstraints { make in
            make.center.equalTo(self.searchEngineScrollView).priorityLow()
            make.left.greaterThanOrEqualTo(self.searchEngineScrollView).priorityHigh()
            make.right.lessThanOrEqualTo(self.searchEngineScrollView).priorityHigh()
            make.top.bottom.equalTo(self.searchEngineScrollView)
        }
    }

    private func layoutSearchEngineScrollView() {
        let keyboardHeight = KeyboardHelper.defaultHelper.currentState?.height ?? 0

        searchEngineScrollView.snp_remakeConstraints { make in
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(-keyboardHeight)
        }
    }

    var searchEngines: SearchEngines! {
        didSet {
            suggestClient?.cancelPendingRequest()

            // Query and reload the table with new search suggestions.
            querySuggestClient()

            // Show the default search engine first.
            suggestClient = SearchSuggestClient(searchEngine: searchEngines.defaultEngine)

            // Reload the footer list of search engines.
            reloadSearchEngines()
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

    private func reloadSearchEngines() {
        searchEngineScrollViewContent.subviews.map({ $0.removeFromSuperview() })

        var leftEdge = searchEngineScrollViewContent.snp_left
        for engine in searchEngines.enabledEngines {
            let engineButton = UIButton()
            engineButton.setImage(engine.image, forState: UIControlState.Normal)
            engineButton.layer.backgroundColor = UIColor.whiteColor().CGColor
            engineButton.addTarget(self, action: "SELdidSelectEngine:", forControlEvents: UIControlEvents.TouchUpInside)
            engineButton.accessibilityLabel = NSString(format: NSLocalizedString("%@ search", comment: "Label for search engine buttons. The argument corresponds to the name of the search engine."), engine.shortName)

            searchEngineScrollViewContent.addSubview(engineButton)
            engineButton.snp_makeConstraints { make in
                make.width.equalTo(EngineButtonWidth)
                make.height.equalTo(EngineButtonHeight)
                make.left.equalTo(leftEdge).offset(EngineButtonInsets.left)
                make.top.bottom.equalTo(self.searchEngineScrollViewContent).insets(EngineButtonInsets)
                if engine === self.searchEngines.enabledEngines.last {
                    make.right.equalTo(self.searchEngineScrollViewContent).offset(-EngineButtonInsets.right)
                }
            }
            leftEdge = engineButton.snp_right
        }
    }

    func SELdidSelectEngine(sender: UIButton) {
        // The UIButtons are the same cardinality and order as the enabledEngines array.
        for i in 0..<searchEngineScrollViewContent.subviews.count {
            let button = searchEngineScrollViewContent.subviews[i] as UIButton
            if button === sender {
                if let url = searchEngines.enabledEngines[i].searchURLForQuery(searchQuery) {
                    searchDelegate?.searchViewController(self, didSelectURL: url)
                }
            }
        }
    }

    func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        animateSearchEnginesWithKeyboard(state)
    }

    func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        animateSearchEnginesWithKeyboard(state)
    }

    private func animateSearchEnginesWithKeyboard(keyboardState: KeyboardState) {
        layoutSearchEngineScrollView()

        UIView.animateWithDuration(keyboardState.animationDuration, animations: {
            UIView.setAnimationCurve(keyboardState.animationCurve)
            self.view.layoutIfNeeded()
        })
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
            case .BookmarksAndHistory:
                return data.count
            }
        }
        return 0
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var url: NSURL?
        if let currentSection = SearchListSection(rawValue: indexPath.section) {
            switch currentSection {
            case .SearchSuggestions:
                let suggestion = searchSuggestions[indexPath.row]

                url = URIFixup().getURL(suggestion)
                if url == nil {
                    // Assume that only the default search engine can provide search suggestions.
                    url = searchEngines?.defaultEngine.searchURLForQuery(suggestion)
                }
            case .BookmarksAndHistory:
                if let site = data[indexPath.row] as? Site {
                    url = NSURL(string: site.url)
                }
            }
        }

        if let url = url {
            searchDelegate?.searchViewController(self, didSelectURL: url)
        }
    }
}

/**
 * UIScrollView that prevents buttons from interfering with scroll.
 */
private class ButtonScrollView: UIScrollView {
    private override func touchesShouldCancelInContentView(view: UIView!) -> Bool {
        return true
    }
}