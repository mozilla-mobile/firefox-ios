/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage
import Glean
import Telemetry

private enum SearchListSection: Int {
    case searchSuggestions
    case bookmarksAndHistory
    static let Count = 2
}

private struct SearchViewControllerUX {
    static var SearchEngineScrollViewBackgroundColor: CGColor { return UIColor.theme.homePanel.toolbarBackground.withAlphaComponent(0.8).cgColor }
    static let SearchEngineScrollViewBorderColor = UIColor.black.withAlphaComponent(0.2).cgColor

    // TODO: This should use ToolbarHeight in BVC. Fix this when we create a shared theming file.
    static let EngineButtonHeight: Float = 44
    static let EngineButtonWidth = EngineButtonHeight * 1.4
    static let EngineButtonBackgroundColor = UIColor.clear.cgColor

    static let SearchImage = "search"
    static let SearchEngineTopBorderWidth = 0.5
    static let SearchPillIconSize = 12

    static var SuggestionBackgroundColor: UIColor { return UIColor.theme.homePanel.searchSuggestionPillBackground }
    static var SuggestionBorderColor: UIColor { return UIColor.theme.homePanel.searchSuggestionPillForeground }
    static let SuggestionBorderWidth: CGFloat = 1
    static let SuggestionCornerRadius: CGFloat = 4
    static let SuggestionInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    static let SuggestionMargin: CGFloat = 8
    static let SuggestionCellVerticalPadding: CGFloat = 10
    static let SuggestionCellMaxRows = 2

    static let IconSize: CGFloat = 23
    static let FaviconSize: CGFloat = 29
    static let IconBorderColor = UIColor(white: 0, alpha: 0.1)
    static let IconBorderWidth: CGFloat = 0.5
}

protocol SearchViewControllerDelegate: AnyObject {
    func searchViewController(_ searchViewController: SearchViewController, didSelectURL url: URL)
    func searchViewController(_ searchViewController: SearchViewController, didLongPressSuggestion suggestion: String)
    func presentSearchSettingsController()
    func searchViewController(_ searchViewController: SearchViewController, didHighlightText text: String, search: Bool)
}

class SearchViewController: SiteTableViewController, KeyboardHelperDelegate, LoaderListener {
    var searchDelegate: SearchViewControllerDelegate?

    fileprivate let isPrivate: Bool
    fileprivate var suggestClient: SearchSuggestClient?

    // Views for displaying the bottom scrollable search engine list. searchEngineScrollView is the
    // scrollable container; searchEngineScrollViewContent contains the actual set of search engine buttons.
    fileprivate let searchEngineContainerView = UIView()
    fileprivate let searchEngineScrollView = ButtonScrollView()
    fileprivate let searchEngineScrollViewContent = UIView()

    fileprivate lazy var bookmarkedBadge: UIImage = {
        return UIImage.templateImageNamed("bookmarked_passive")!.tinted(withColor: .lightGray).createScaled(CGSize(width: 16, height: 16))
    }()

    // Cell for the suggestion flow layout. Since heightForHeaderInSection is called *before*
    // cellForRowAtIndexPath, we create the cell to find its height before it's added to the table.
    fileprivate let suggestionCell = SuggestionCell(style: .default, reuseIdentifier: nil)

    static var userAgent: String?

    init(profile: Profile, isPrivate: Bool) {
        self.isPrivate = isPrivate
        super.init(profile: profile)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        view.backgroundColor = UIColor.theme.homePanel.panelBackground
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        view.addSubview(blur)

        super.viewDidLoad()

        KeyboardHelper.defaultHelper.addDelegate(self)

        searchEngineContainerView.layer.backgroundColor = SearchViewControllerUX.SearchEngineScrollViewBackgroundColor
        searchEngineContainerView.layer.shadowRadius = 0
        searchEngineContainerView.layer.shadowOpacity = 100
        searchEngineContainerView.layer.shadowOffset = CGSize(width: 0, height: -SearchViewControllerUX.SearchEngineTopBorderWidth)
        searchEngineContainerView.layer.shadowColor = SearchViewControllerUX.SearchEngineScrollViewBorderColor
        searchEngineContainerView.clipsToBounds = false

        searchEngineScrollView.decelerationRate = UIScrollView.DecelerationRate.fast
        searchEngineContainerView.addSubview(searchEngineScrollView)
        view.addSubview(searchEngineContainerView)

        searchEngineScrollViewContent.layer.backgroundColor = UIColor.clear.cgColor
        searchEngineScrollView.addSubview(searchEngineScrollViewContent)

        layoutTable()
        layoutSearchEngineScrollView()

        searchEngineScrollViewContent.snp.makeConstraints { make in
            make.center.equalTo(self.searchEngineScrollView).priority(10)
            //left-align the engines on iphones, center on ipad
            if UIScreen.main.traitCollection.horizontalSizeClass == .compact {
                make.left.equalTo(self.searchEngineScrollView).priority(1000)
            } else {
                make.left.greaterThanOrEqualTo(self.searchEngineScrollView).priority(1000)
            }
            make.right.lessThanOrEqualTo(self.searchEngineScrollView).priority(1000)
            make.top.equalTo(self.searchEngineScrollView)
            make.bottom.equalTo(self.searchEngineScrollView)
        }

        blur.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
    
        searchEngineContainerView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
        }

        suggestionCell.delegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(dynamicFontChanged), name: .DynamicFontChanged, object: nil)
    }

    @objc func dynamicFontChanged(_ notification: Notification) {
        guard notification.name == .DynamicFontChanged else { return }

        reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadSearchEngines()
        reloadData()
    }

    fileprivate func layoutSearchEngineScrollView() {
        let keyboardHeight = KeyboardHelper.defaultHelper.currentState?.intersectionHeightForView(self.view) ?? 0
        searchEngineScrollView.snp.remakeConstraints { make in
            make.left.right.top.equalToSuperview()
            if keyboardHeight == 0 {
                make.bottom.equalTo(view.safeArea.bottom)
            } else {
                make.bottom.equalTo(view).offset(-keyboardHeight)
            }
        }
    }

    var searchEngines: SearchEngines! {
        didSet {
            suggestClient?.cancelPendingRequest()

            // Query and reload the table with new search suggestions.
            querySuggestClient()

            // Show the default search engine first.
            if !isPrivate {
                let ua = SearchViewController.userAgent ?? "FxSearch"
                suggestClient = SearchSuggestClient(searchEngine: searchEngines.defaultEngine, userAgent: ua)
            }

            // Reload the footer list of search engines.
            reloadSearchEngines()
        }
    }

    fileprivate var quickSearchEngines: [OpenSearchEngine] {
        var engines = searchEngines.quickSearchEngines

        // If we're not showing search suggestions, the default search engine won't be visible
        // at the top of the table. Show it with the others in the bottom search bar.
        if isPrivate || !searchEngines.shouldShowSearchSuggestions {
            engines?.insert(searchEngines.defaultEngine, at: 0)
        }

        return engines!
    }

    var searchQuery: String = "" {
        didSet {
            // Reload the tableView to show the updated text in each engine.
            reloadData()
        }
    }

    override func reloadData() {
        querySuggestClient()
    }

    fileprivate func layoutTable() {
        tableView.snp.remakeConstraints { make in
            make.top.equalTo(self.view.snp.top)
            make.leading.trailing.equalTo(self.view)
            make.bottom.equalTo(self.searchEngineScrollView.snp.top)
        }
    }

    fileprivate func reloadSearchEngines() {
        searchEngineScrollViewContent.subviews.forEach { $0.removeFromSuperview() }
        var leftEdge = searchEngineScrollViewContent.snp.left

        //search settings icon
        let searchButton = UIButton()
        searchButton.setImage(UIImage(named: "quickSearch"), for: [])
        searchButton.imageView?.contentMode = .center
        searchButton.layer.backgroundColor = SearchViewControllerUX.EngineButtonBackgroundColor
        searchButton.addTarget(self, action: #selector(didClickSearchButton), for: .touchUpInside)
        searchButton.accessibilityLabel = String(format: NSLocalizedString("Search Settings", tableName: "Search", comment: "Label for search settings button."))

        searchEngineScrollViewContent.addSubview(searchButton)
        searchButton.snp.makeConstraints { make in
            make.size.equalTo(SearchViewControllerUX.FaviconSize)
            //offset the left edge to align with search results
            make.left.equalTo(leftEdge).offset(SearchViewControllerUX.SuggestionMargin * 2)
            make.top.equalTo(self.searchEngineScrollViewContent).offset(SearchViewControllerUX.SuggestionMargin)
            make.bottom.equalTo(self.searchEngineScrollViewContent).offset(-SearchViewControllerUX.SuggestionMargin)
        }

        //search engines
        leftEdge = searchButton.snp.right
        for engine in quickSearchEngines {
            let engineButton = UIButton()
            engineButton.setImage(engine.image, for: [])
            engineButton.imageView?.contentMode = .scaleAspectFit
            engineButton.imageView?.layer.cornerRadius = 4
            engineButton.layer.backgroundColor = SearchViewControllerUX.EngineButtonBackgroundColor
            engineButton.addTarget(self, action: #selector(didSelectEngine), for: .touchUpInside)
            engineButton.accessibilityLabel = String(format: NSLocalizedString("%@ search", tableName: "Search", comment: "Label for search engine buttons. The argument corresponds to the name of the search engine."), engine.shortName)

            engineButton.imageView?.snp.makeConstraints { make in
                make.width.height.equalTo(SearchViewControllerUX.FaviconSize)
                return
            }

            searchEngineScrollViewContent.addSubview(engineButton)
            engineButton.snp.makeConstraints { make in
                make.width.equalTo(SearchViewControllerUX.EngineButtonWidth)
                make.height.equalTo(SearchViewControllerUX.EngineButtonHeight)
                make.left.equalTo(leftEdge)
                make.top.equalTo(self.searchEngineScrollViewContent)
                make.bottom.equalTo(self.searchEngineScrollViewContent)
                if engine === self.searchEngines.quickSearchEngines.last {
                    make.right.equalTo(self.searchEngineScrollViewContent)
                }
            }
            leftEdge = engineButton.snp.right
        }
    }

    @objc func didSelectEngine(_ sender: UIButton) {
        // The UIButtons are the same cardinality and order as the array of quick search engines.
        // Subtract 1 from index to account for magnifying glass accessory.
        guard let index = searchEngineScrollViewContent.subviews.firstIndex(of: sender) else {
            assertionFailure()
            return
        }

        let engine = quickSearchEngines[index - 1]

        guard let url = engine.searchURLForQuery(searchQuery) else {
            assertionFailure()
            return
        }

        Telemetry.default.recordSearch(location: .quickSearch, searchEngine: engine.engineID ?? "other")
        GleanMetrics.Search.counts["\(engine.engineID ?? "custom").\(SearchesMeasurement.SearchLocation.quickSearch.rawValue)"].add()

        searchDelegate?.searchViewController(self, didSelectURL: url)
    }

    @objc func didClickSearchButton() {
        self.searchDelegate?.presentSearchSettingsController()
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        animateSearchEnginesWithKeyboard(state)
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        animateSearchEnginesWithKeyboard(state)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // The height of the suggestions row may change, so call reloadData() to recalculate cell heights.
        coordinator.animate(alongsideTransition: { _ in
            self.tableView.reloadData()
        }, completion: nil)
    }

    fileprivate func animateSearchEnginesWithKeyboard(_ keyboardState: KeyboardState) {
        layoutSearchEngineScrollView()

        UIView.animate(withDuration: keyboardState.animationDuration, animations: {
            UIView.setAnimationCurve(keyboardState.animationCurve)
            self.view.layoutIfNeeded()
        })
    }

    fileprivate func querySuggestClient() {
        suggestClient?.cancelPendingRequest()

        if searchQuery.isEmpty || !searchEngines.shouldShowSearchSuggestions || searchQuery.looksLikeAURL() {
            suggestionCell.suggestions = []
            tableView.reloadData()
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
                    print("Error: Invalid search suggestion data")
                default:
                    print("Error: \(error.description)")
                }
            } else {
                self.suggestionCell.suggestions = suggestions!
            }

            // If there are no suggestions, just use whatever the user typed.
            if suggestions?.isEmpty ?? true {
                self.suggestionCell.suggestions = [self.searchQuery]
            }

            // Reload the tableView to show the new list of search suggestions.
            self.tableView.reloadData()
        })
    }

    func loader(dataLoaded data: Cursor<Site>) {
        self.data = data
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = SearchListSection(rawValue: indexPath.section)!
        if section == SearchListSection.bookmarksAndHistory {
            if let site = data[indexPath.row] {
                if let url = URL(string: site.url) {
                    searchDelegate?.searchViewController(self, didSelectURL: url)
                    TelemetryWrapper.recordEvent(category: .action, method: .open, object: .bookmark, value: .awesomebarResults)
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let currentSection = SearchListSection(rawValue: indexPath.section) {
            switch currentSection {
            case .searchSuggestions:
                // heightForRowAtIndexPath is called *before* the cell is created, so to get the height,
                // force a layout pass first.
                suggestionCell.layoutIfNeeded()
                return suggestionCell.frame.height
            default:
                return super.tableView(tableView, heightForRowAt: indexPath)
            }
        }

        return 0
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch SearchListSection(rawValue: indexPath.section)! {
        case .searchSuggestions:
            suggestionCell.imageView?.image = searchEngines.defaultEngine.image
            suggestionCell.imageView?.isAccessibilityElement = true
            suggestionCell.imageView?.accessibilityLabel = String(format: NSLocalizedString("Search suggestions from %@", tableName: "Search", comment: "Accessibility label for image of default search engine displayed left to the actual search suggestions from the engine. The parameter substituted for \"%@\" is the name of the search engine. E.g.: Search suggestions from Google"), searchEngines.defaultEngine.shortName)
            return suggestionCell

        case .bookmarksAndHistory:
            let cell = super.tableView(tableView, cellForRowAt: indexPath)
            if let site = data[indexPath.row] {
                if let cell = cell as? TwoLineTableViewCell {
                    let isBookmark = site.bookmarked ?? false
                    cell.setLines(site.title, detailText: site.url)
                    cell.setRightBadge(isBookmark ? self.bookmarkedBadge : nil)
                    cell.imageView?.layer.borderColor = SearchViewControllerUX.IconBorderColor.cgColor
                    cell.imageView?.layer.borderWidth = SearchViewControllerUX.IconBorderWidth
                    cell.imageView?.contentMode = .center
                    cell.imageView?.setImageAndBackground(forIcon: site.icon, website: site.tileURL) { [weak cell] in
                        cell?.imageView?.image = cell?.imageView?.image?.createScaled(CGSize(width: SearchViewControllerUX.IconSize, height: SearchViewControllerUX.IconSize))
                    }
                }
            }
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch SearchListSection(rawValue: section)! {
        case .searchSuggestions:
            return searchEngines.shouldShowSearchSuggestions && !searchQuery.looksLikeAURL() && !isPrivate ? 1 : 0
        case .bookmarksAndHistory:
            return data.count
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return SearchListSection.Count
    }

    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        guard let section = SearchListSection(rawValue: indexPath.section) else {
            return
        }

        if section == .bookmarksAndHistory,
            let suggestion = data[indexPath.item] {
            searchDelegate?.searchViewController(self, didHighlightText: suggestion.url, search: false)
        }
    }

    override func applyTheme() {
        super.applyTheme()

        reloadData()
    }
}

extension SearchViewController {
    func handleKeyCommands(sender: UIKeyCommand) {
        let initialSection = SearchListSection.bookmarksAndHistory.rawValue
        guard let current = tableView.indexPathForSelectedRow else {
            let count = tableView(tableView, numberOfRowsInSection: initialSection)
            if sender.input == UIKeyCommand.inputDownArrow, count > 0 {
                let next = IndexPath(item: 0, section: initialSection)
                self.tableView(tableView, didHighlightRowAt: next)
                tableView.selectRow(at: next, animated: false, scrollPosition: .top)
            }
            return
        }

        let nextSection: Int
        let nextItem: Int
        guard let input = sender.input else { return }
        switch input {
        case UIKeyCommand.inputUpArrow:
            // we're going down, we should check if we've reached the first item in this section.
            if current.item == 0 {
                // We have, so check if we can decrement the section.
                if current.section == initialSection {
                    // We've reached the first item in the first section.
                    searchDelegate?.searchViewController(self, didHighlightText: searchQuery, search: false)
                    return
                } else {
                    nextSection = current.section - 1
                    nextItem = tableView(tableView, numberOfRowsInSection: nextSection) - 1
                }
            } else {
                nextSection = current.section
                nextItem = current.item - 1
            }
        case UIKeyCommand.inputDownArrow:
            let currentSectionItemsCount = tableView(tableView, numberOfRowsInSection: current.section)
            if current.item == currentSectionItemsCount - 1 {
                if current.section == tableView.numberOfSections - 1 {
                    // We've reached the last item in the last section
                    return
                } else {
                    // We can go to the next section.
                    nextSection = current.section + 1
                    nextItem = 0
                }
            } else {
                nextSection = current.section
                nextItem = current.item + 1
            }
        default:
            return
        }
        guard nextItem >= 0 else {
            return
        }
        let next = IndexPath(item: nextItem, section: nextSection)
        self.tableView(tableView, didHighlightRowAt: next)
        tableView.selectRow(at: next, animated: false, scrollPosition: .middle)
    }
}

extension SearchViewController: SuggestionCellDelegate {
    fileprivate func suggestionCell(_ suggestionCell: SuggestionCell, didSelectSuggestion suggestion: String) {
        // Assume that only the default search engine can provide search suggestions.
        let engine = searchEngines.defaultEngine

        if let url = engine.searchURLForQuery(suggestion) {
            Telemetry.default.recordSearch(location: .suggestion, searchEngine: engine.engineID ?? "other")
            GleanMetrics.Search.counts["\(engine.engineID ?? "custom").\(SearchesMeasurement.SearchLocation.suggestion.rawValue)"].add()

            searchDelegate?.searchViewController(self, didSelectURL: url)
        }
    }

    fileprivate func suggestionCell(_ suggestionCell: SuggestionCell, didLongPressSuggestion suggestion: String) {
        searchDelegate?.searchViewController(self, didLongPressSuggestion: suggestion)
    }
}

/**
 * Private extension containing string operations specific to this view controller
 */
fileprivate extension String {
    func looksLikeAURL() -> Bool {
        // The assumption here is that if the user is typing in a forward slash and there are no spaces
        // involved, it's going to be a URL. If we type a space, any url would be invalid.
        // See https://bugzilla.mozilla.org/show_bug.cgi?id=1192155 for additional details.
        return self.contains("/") && !self.contains(" ")
    }
}

/**
 * UIScrollView that prevents buttons from interfering with scroll.
 */
fileprivate class ButtonScrollView: UIScrollView {
    fileprivate override func touchesShouldCancel(in view: UIView) -> Bool {
        return true
    }
}

fileprivate protocol SuggestionCellDelegate: AnyObject {
    func suggestionCell(_ suggestionCell: SuggestionCell, didSelectSuggestion suggestion: String)
    func suggestionCell(_ suggestionCell: SuggestionCell, didLongPressSuggestion suggestion: String)
}

/**
 * Cell that wraps a list of search suggestion buttons.
 */
fileprivate class SuggestionCell: UITableViewCell {
    weak var delegate: SuggestionCellDelegate?
    let container = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        isAccessibilityElement = false
        accessibilityLabel = nil
        layoutMargins = .zero
        separatorInset = .zero
        selectionStyle = .none

        container.backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
        backgroundColor = UIColor.clear
        contentView.addSubview(container)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var suggestions: [String] = [] {
        didSet {
            for view in container.subviews {
                view.removeFromSuperview()
            }

            for suggestion in suggestions {
                let button = SuggestionButton()
                button.setTitle(suggestion, for: [])
                button.addTarget(self, action: #selector(didSelectSuggestion), for: .touchUpInside)
                button.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(didLongPressSuggestion)))

                // If this is the first image, add the search icon.
                if container.subviews.isEmpty {
                    let size = SearchViewControllerUX.SearchPillIconSize
                    let image = UIImage.templateImageNamed(SearchViewControllerUX.SearchImage)?.createScaled(CGSize(width: size, height: size)).tinted(withColor: UIColor.theme.homePanel.searchSuggestionPillForeground)
                    button.setImage(image, for: [])
                    if UIApplication.shared.userInterfaceLayoutDirection == .leftToRight {
                        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
                    } else {
                        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
                    }
                }

                container.addSubview(button)
            }

            setNeedsLayout()
        }
    }

    @objc
    func didSelectSuggestion(_ sender: UIButton) {
        delegate?.suggestionCell(self, didSelectSuggestion: sender.titleLabel!.text!)
    }

    @objc
    func didLongPressSuggestion(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            if let button = recognizer.view as! UIButton? {
                delegate?.suggestionCell(self, didLongPressSuggestion: button.titleLabel!.text!)
            }
        }
    }

    fileprivate override func layoutSubviews() {
        super.layoutSubviews()

        // The left bounds of the suggestions, aligned with where text would be displayed.
        let textLeft: CGFloat = 61

        // The maximum width of the container, after which suggestions will wrap to the next line.
        let maxWidth = contentView.frame.width

        let imageSize = CGFloat(SearchViewControllerUX.FaviconSize)

        // The height of the suggestions container (minus margins), used to determine the frame.
        // We set it to imageSize.height as a minimum since we don't want the cell to be shorter than the icon
        var height: CGFloat = imageSize

        var currentLeft = textLeft
        var currentTop = SearchViewControllerUX.SuggestionCellVerticalPadding
        var currentRow = 0

        for view in container.subviews {
            let button = view as! UIButton
            var buttonSize = button.intrinsicContentSize

            // Update our base frame height by the max size of either the image or the button so we never
            // make the cell smaller than any of the two
            if height == imageSize {
                height = max(buttonSize.height, imageSize)
            }

            var width = currentLeft + buttonSize.width + SearchViewControllerUX.SuggestionMargin
            if width > maxWidth {
                // Only move to the next row if there's already a suggestion on this row.
                // Otherwise, the suggestion is too big to fit and will be resized below.
                if currentLeft > textLeft {
                    currentRow += 1
                    if currentRow >= SearchViewControllerUX.SuggestionCellMaxRows {
                        // Don't draw this button if it doesn't fit on the row.
                        button.frame = .zero
                        continue
                    }

                    currentLeft = textLeft
                    currentTop += buttonSize.height + SearchViewControllerUX.SuggestionMargin
                    height += buttonSize.height + SearchViewControllerUX.SuggestionMargin
                    width = currentLeft + buttonSize.width + SearchViewControllerUX.SuggestionMargin
                }

                // If the suggestion is too wide to fit on its own row, shrink it.
                if width > maxWidth {
                    buttonSize.width = maxWidth - currentLeft - SearchViewControllerUX.SuggestionMargin
                }
            }

            button.frame = CGRect(x: currentLeft, y: currentTop, width: buttonSize.width, height: buttonSize.height)
            currentLeft += buttonSize.width + SearchViewControllerUX.SuggestionMargin
        }

        frame.size.height = height + 2 * SearchViewControllerUX.SuggestionCellVerticalPadding
        contentView.frame = bounds
        container.frame = bounds

        let imageX = (textLeft - imageSize) / 2
        let imageY = (frame.size.height - imageSize) / 2
        imageView!.frame = CGRect(x: imageX, y: imageY, width: imageSize, height: imageSize)
    }
}

/**
 * Rounded search suggestion button that highlights when selected.
 */
fileprivate class SuggestionButton: InsetButton {
    override init(frame: CGRect) {
        super.init(frame: frame)

        setTitleColor(UIColor.theme.homePanel.searchSuggestionPillForeground, for: [])
        setTitleColor(UIColor.Photon.White100, for: .highlighted)
        titleLabel?.font = DynamicFontHelper.defaultHelper.DefaultMediumFont
        backgroundColor = SearchViewControllerUX.SuggestionBackgroundColor
        layer.borderColor = SearchViewControllerUX.SuggestionBorderColor.cgColor
        layer.borderWidth = SearchViewControllerUX.SuggestionBorderWidth
        layer.cornerRadius = SearchViewControllerUX.SuggestionCornerRadius
        contentEdgeInsets = SearchViewControllerUX.SuggestionInsets

        accessibilityHint = NSLocalizedString("Searches for the suggestion", comment: "Accessibility hint describing the action performed when a search suggestion is clicked")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UIColor.theme.general.highlightBlue : SearchViewControllerUX.SuggestionBackgroundColor
        }
    }
}
