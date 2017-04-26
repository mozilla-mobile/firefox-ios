/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage
import Telemetry

private let PromptMessage = NSLocalizedString("Turn on search suggestions?", tableName: "Search", comment: "Prompt shown before enabling provider search queries")
private let PromptYes = NSLocalizedString("Yes", tableName: "Search", comment: "For search suggestions prompt. This string should be short so it fits nicely on the prompt row.")
private let PromptNo = NSLocalizedString("No", tableName: "Search", comment: "For search suggestions prompt. This string should be short so it fits nicely on the prompt row.")

private enum SearchListSection: Int {
    case searchSuggestions
    case bookmarksAndHistory
    static let Count = 2
}

private struct SearchViewControllerUX {
    static let SearchEngineScrollViewBackgroundColor = UIColor.white.withAlphaComponent(0.8).cgColor
    static let SearchEngineScrollViewBorderColor = UIColor.black.withAlphaComponent(0.2).cgColor

    // TODO: This should use ToolbarHeight in BVC. Fix this when we create a shared theming file.
    static let EngineButtonHeight: Float = 44
    static let EngineButtonWidth = EngineButtonHeight * 1.4
    static let EngineButtonBackgroundColor = UIColor.clear.cgColor

    static let SearchImage = "search"
    static let SearchEngineTopBorderWidth = 0.5
    static let SearchImageHeight: Float = 44
    static let SearchImageWidth: Float = 24

    static let SuggestionBackgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.8)
    static let SuggestionBorderColor = UIConstants.HighlightBlue
    static let SuggestionBorderWidth: CGFloat = 1
    static let SuggestionCornerRadius: CGFloat = 4
    static let SuggestionInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    static let SuggestionMargin: CGFloat = 8
    static let SuggestionCellVerticalPadding: CGFloat = 10
    static let SuggestionCellMaxRows = 2

    static let PromptColor = UIConstants.PanelBackgroundColor
    static let PromptFont = UIFont.systemFont(ofSize: 12, weight: UIFontWeightRegular)
    static let PromptYesFont = UIFont.systemFont(ofSize: 15, weight: UIFontWeightBold)
    static let PromptNoFont = UIFont.systemFont(ofSize: 15, weight: UIFontWeightRegular)
    static let PromptInsets = UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 12)
    static let PromptButtonColor = UIColor(rgb: 0x007aff)

    static let IconSize: CGFloat = 23
    static let IconBorderColor = UIColor(white: 0, alpha: 0.1)
    static let IconBorderWidth: CGFloat = 0.5
}

protocol SearchViewControllerDelegate: class {
    func searchViewController(_ searchViewController: SearchViewController, didSelectURL url: URL)
    func presentSearchSettingsController()
}

class SearchViewController: SiteTableViewController, KeyboardHelperDelegate, LoaderListener {
    var searchDelegate: SearchViewControllerDelegate?

    fileprivate let isPrivate: Bool
    fileprivate var suggestClient: SearchSuggestClient?

    // Views for displaying the bottom scrollable search engine list. searchEngineScrollView is the
    // scrollable container; searchEngineScrollViewContent contains the actual set of search engine buttons.
    fileprivate let searchEngineScrollView = ButtonScrollView()
    fileprivate let searchEngineScrollViewContent = UIView()

    fileprivate lazy var bookmarkedBadge: UIImage = {
        return UIImage(named: "bookmarked_passive")!
    }()

    // Cell for the suggestion flow layout. Since heightForHeaderInSection is called *before*
    // cellForRowAtIndexPath, we create the cell to find its height before it's added to the table.
    fileprivate let suggestionCell = SuggestionCell(style: UITableViewCellStyle.default, reuseIdentifier: nil)

    fileprivate var suggestionPrompt: UIView?
    static var userAgent: String?

    init(isPrivate: Bool) {
        self.isPrivate = isPrivate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        view.backgroundColor = UIConstants.PanelBackgroundColor
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.light))
        view.addSubview(blur)

        super.viewDidLoad()

        KeyboardHelper.defaultHelper.addDelegate(self)

        searchEngineScrollView.layer.backgroundColor = SearchViewControllerUX.SearchEngineScrollViewBackgroundColor
        searchEngineScrollView.layer.shadowRadius = 0
        searchEngineScrollView.layer.shadowOpacity = 100
        searchEngineScrollView.layer.shadowOffset = CGSize(width: 0, height: -SearchViewControllerUX.SearchEngineTopBorderWidth)
        searchEngineScrollView.layer.shadowColor = SearchViewControllerUX.SearchEngineScrollViewBorderColor
        searchEngineScrollView.clipsToBounds = false

        searchEngineScrollView.decelerationRate = UIScrollViewDecelerationRateFast
        view.addSubview(searchEngineScrollView)

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

        suggestionCell.delegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(SearchViewController.SELDynamicFontChanged(_:)), name: NotificationDynamicFontChanged, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: NotificationDynamicFontChanged, object: nil)
    }

    func SELDynamicFontChanged(_ notification: Notification) {
        guard notification.name == NotificationDynamicFontChanged else { return }

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
            if !isPrivate {
                let ua = SearchViewController.userAgent as String! ?? "FxSearch"
                suggestClient = SearchSuggestClient(searchEngine: searchEngines.defaultEngine, userAgent: ua)
            }

            // Reload the footer list of search engines.
            reloadSearchEngines()

            layoutSuggestionsOptInPrompt()
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

    fileprivate func layoutSuggestionsOptInPrompt() {
        if isPrivate || !(searchEngines?.shouldShowSearchSuggestionsOptIn ?? false) {
            // Make sure any pending layouts are drawn so they don't get coupled
            // with the "slide up" animation below.
            view.layoutIfNeeded()

            // Set the prompt to nil so layoutTable() aligns the top of the table
            // to the top of the view. We still need a reference to the prompt so
            // we can remove it from the controller after the animation is done.
            let prompt = suggestionPrompt
            suggestionPrompt = nil
            layoutTable()

            UIView.animate(withDuration: 0.2,
                animations: {
                    self.view.layoutIfNeeded()
                    prompt?.alpha = 0
                },
                completion: { _ in
                    prompt?.removeFromSuperview()
                    return
                })
            return
        }

        let prompt = UIView()
        prompt.backgroundColor = SearchViewControllerUX.PromptColor

        let promptBottomBorder = UIView()
        promptBottomBorder.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        prompt.addSubview(promptBottomBorder)

        // Insert behind the tableView so the tableView slides on top of it
        // when the prompt is dismissed.
        view.insertSubview(prompt, belowSubview: tableView)

        suggestionPrompt = prompt

        let promptImage = UIImageView()
        promptImage.image = UIImage(named: SearchViewControllerUX.SearchImage)
        prompt.addSubview(promptImage)

        let promptLabel = UILabel()
        promptLabel.text = PromptMessage
        promptLabel.font = SearchViewControllerUX.PromptFont
        promptLabel.numberOfLines = 0
        promptLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        prompt.addSubview(promptLabel)

        let promptYesButton = InsetButton()
        promptYesButton.setTitle(PromptYes, for: UIControlState())
        promptYesButton.setTitleColor(SearchViewControllerUX.PromptButtonColor, for: UIControlState.normal)
        promptYesButton.titleLabel?.font = SearchViewControllerUX.PromptYesFont
        promptYesButton.titleEdgeInsets = SearchViewControllerUX.PromptInsets
        // If the prompt message doesn't fit, this prevents it from pushing the buttons
        // off the row and makes it wrap instead.
        promptYesButton.setContentCompressionResistancePriority(1000, for: UILayoutConstraintAxis.horizontal)
        promptYesButton.addTarget(self, action: #selector(SearchViewController.SELdidClickOptInYes), for: UIControlEvents.touchUpInside)
        prompt.addSubview(promptYesButton)

        let promptNoButton = InsetButton()
        promptNoButton.setTitle(PromptNo, for: UIControlState())
        promptNoButton.setTitleColor(SearchViewControllerUX.PromptButtonColor, for: UIControlState.normal)
        promptNoButton.titleLabel?.font = SearchViewControllerUX.PromptNoFont
        promptNoButton.titleEdgeInsets = SearchViewControllerUX.PromptInsets
        // If the prompt message doesn't fit, this prevents it from pushing the buttons
        // off the row and makes it wrap instead.
        promptNoButton.setContentCompressionResistancePriority(1000, for: UILayoutConstraintAxis.horizontal)
        promptNoButton.addTarget(self, action: #selector(SearchViewController.SELdidClickOptInNo), for: UIControlEvents.touchUpInside)
        prompt.addSubview(promptNoButton)

        // otherwise the label (i.e. question) is visited by VoiceOver *after* yes and no buttons
        prompt.accessibilityElements = [promptImage, promptLabel, promptYesButton, promptNoButton]

        promptImage.snp.makeConstraints { make in
            make.left.equalTo(prompt).offset(SearchViewControllerUX.PromptInsets.left)
            make.centerY.equalTo(prompt)
        }

        promptLabel.snp.makeConstraints { make in
            make.left.equalTo(promptImage.snp.right).offset(SearchViewControllerUX.PromptInsets.left)
            let insets = SearchViewControllerUX.PromptInsets
            make.top.equalTo(prompt).inset(insets.top)
            make.bottom.equalTo(prompt).inset(insets.bottom)
            make.right.lessThanOrEqualTo(promptYesButton.snp.left)
            return
        }

        promptNoButton.snp.makeConstraints { make in
            make.right.equalTo(prompt).inset(SearchViewControllerUX.PromptInsets.right)
            make.centerY.equalTo(prompt)
        }

        promptYesButton.snp.makeConstraints { make in
            make.right.equalTo(promptNoButton.snp.left).inset(SearchViewControllerUX.PromptInsets.right)
            make.centerY.equalTo(prompt)
        }

        promptBottomBorder.snp.makeConstraints { make in
            make.trailing.leading.equalTo(self.view)
            make.top.equalTo(prompt.snp.bottom).offset(-1)
            make.height.equalTo(1)
        }

        prompt.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(self.view)
        }

        layoutTable()
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
            make.top.equalTo(self.suggestionPrompt?.snp.bottom ?? self.view.snp.top)
            make.leading.trailing.equalTo(self.view)
            make.bottom.equalTo(self.searchEngineScrollView.snp.top)
        }
    }

    fileprivate func reloadSearchEngines() {
        searchEngineScrollViewContent.subviews.forEach { $0.removeFromSuperview() }
        var leftEdge = searchEngineScrollViewContent.snp.left

        //search settings icon
        let searchButton = UIButton()
        searchButton.setImage(UIImage(named: "quickSearch"), for: UIControlState())
        searchButton.imageView?.contentMode = UIViewContentMode.center
        searchButton.layer.backgroundColor = SearchViewControllerUX.EngineButtonBackgroundColor
        searchButton.addTarget(self, action: #selector(SearchViewController.SELdidClickSearchButton), for: UIControlEvents.touchUpInside)
        searchButton.accessibilityLabel = String(format: NSLocalizedString("Search Settings", tableName: "Search", comment: "Label for search settings button."))

        searchButton.imageView?.snp.makeConstraints { make in
            make.width.height.equalTo(SearchViewControllerUX.SearchImageWidth)
            return
        }

        searchEngineScrollViewContent.addSubview(searchButton)
        searchButton.snp.makeConstraints { make in
            make.width.equalTo(SearchViewControllerUX.SearchImageWidth)
            make.height.equalTo(SearchViewControllerUX.SearchImageHeight)
            //offset the left edge to align with search results
            make.left.equalTo(leftEdge).offset(SearchViewControllerUX.PromptInsets.left)
            make.top.equalTo(self.searchEngineScrollViewContent)
            make.bottom.equalTo(self.searchEngineScrollViewContent)
        }

        //search engines
        leftEdge = searchButton.snp.right
        for engine in quickSearchEngines {
            let engineButton = UIButton()
            engineButton.setImage(engine.image, for: UIControlState())
            engineButton.imageView?.contentMode = UIViewContentMode.scaleAspectFit
            engineButton.layer.backgroundColor = SearchViewControllerUX.EngineButtonBackgroundColor
            engineButton.addTarget(self, action: #selector(SearchViewController.SELdidSelectEngine(_:)), for: UIControlEvents.touchUpInside)
            engineButton.accessibilityLabel = String(format: NSLocalizedString("%@ search", tableName: "Search", comment: "Label for search engine buttons. The argument corresponds to the name of the search engine."), engine.shortName)

            engineButton.imageView?.snp.makeConstraints { make in
                make.width.height.equalTo(OpenSearchEngine.PreferredIconSize)
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

    func SELdidSelectEngine(_ sender: UIButton) {
        // The UIButtons are the same cardinality and order as the array of quick search engines.
        // Subtract 1 from index to account for magnifying glass accessory.
        guard let index = searchEngineScrollViewContent.subviews.index(of: sender) else {
            assertionFailure()
            return
        }

        let engine = quickSearchEngines[index - 1]

        guard let url = engine.searchURLForQuery(searchQuery) else {
            assertionFailure()
            return
        }

        Telemetry.recordEvent(SearchTelemetry.makeEvent(engine, source: .QuickSearch))
        searchDelegate?.searchViewController(self, didSelectURL: url)
    }

    func SELdidClickSearchButton() {
        self.searchDelegate?.presentSearchSettingsController()  
    }

    func SELdidClickOptInYes() {
        searchEngines.shouldShowSearchSuggestions = true
        searchEngines.shouldShowSearchSuggestionsOptIn = false
        querySuggestClient()
        layoutSuggestionsOptInPrompt()
        reloadSearchEngines()
    }

    func SELdidClickOptInNo() {
        searchEngines.shouldShowSearchSuggestions = false
        searchEngines.shouldShowSearchSuggestionsOptIn = false
        layoutSuggestionsOptInPrompt()
        reloadSearchEngines()
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

    func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        let section = SearchListSection(rawValue: indexPath.section)!
        if section == SearchListSection.bookmarksAndHistory {
            if let site = data[indexPath.row] {
                if let url = URL(string: site.url) {
                    searchDelegate?.searchViewController(self, didSelectURL: url)
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
                    cell.imageView!.layer.borderColor = SearchViewControllerUX.IconBorderColor.cgColor
                    cell.imageView!.layer.borderWidth = SearchViewControllerUX.IconBorderWidth
                    cell.imageView?.setIcon(site.icon, forURL: site.tileURL, completed: { (color, url) in
                        cell.imageView?.image = cell.imageView?.image?.createScaled(CGSize(width: SearchViewControllerUX.IconSize, height: SearchViewControllerUX.IconSize))
                        cell.imageView?.contentMode = .center
                    })
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

    func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
        return SearchListSection.Count
    }
}

extension SearchViewController: SuggestionCellDelegate {
    fileprivate func suggestionCell(_ suggestionCell: SuggestionCell, didSelectSuggestion suggestion: String) {
        // Assume that only the default search engine can provide search suggestions.
        let engine = searchEngines.defaultEngine

        var url = URIFixup.getURL(suggestion)
        if url == nil {
            url = engine.searchURLForQuery(suggestion)
        }

        Telemetry.recordEvent(SearchTelemetry.makeEvent(engine, source: .Suggestion))

        if let url = url {
            searchDelegate?.searchViewController(self, didSelectURL: url)
        }
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

fileprivate protocol SuggestionCellDelegate: class {
    func suggestionCell(_ suggestionCell: SuggestionCell, didSelectSuggestion suggestion: String)
}

/**
 * Cell that wraps a list of search suggestion buttons.
 */
fileprivate class SuggestionCell: UITableViewCell {
    weak var delegate: SuggestionCellDelegate?
    let container = UIView()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        isAccessibilityElement = false
        accessibilityLabel = nil
        layoutMargins = UIEdgeInsets.zero
        separatorInset = UIEdgeInsets.zero
        selectionStyle = UITableViewCellSelectionStyle.none

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
                button.setTitle(suggestion, for: UIControlState())
                button.addTarget(self, action: #selector(SuggestionCell.SELdidSelectSuggestion(_:)), for: UIControlEvents.touchUpInside)

                // If this is the first image, add the search icon.
                if container.subviews.isEmpty {
                    let image = UIImage(named: SearchViewControllerUX.SearchImage)
                    button.setImage(image, for: UIControlState())
                    button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
                }

                container.addSubview(button)
            }

            setNeedsLayout()
        }
    }

    @objc
    func SELdidSelectSuggestion(_ sender: UIButton) {
        delegate?.suggestionCell(self, didSelectSuggestion: sender.titleLabel!.text!)
    }

    fileprivate override func layoutSubviews() {
        super.layoutSubviews()

        // The left bounds of the suggestions, aligned with where text would be displayed.
        let textLeft: CGFloat = 48

        // The maximum width of the container, after which suggestions will wrap to the next line.
        let maxWidth = contentView.frame.width

        let imageSize = CGFloat(OpenSearchEngine.PreferredIconSize)

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
                        button.frame = CGRect.zero
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
        contentView.frame = frame
        container.frame = frame

        let imageX = (48 - imageSize) / 2
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

        setTitleColor(UIConstants.HighlightBlue, for: UIControlState())
        setTitleColor(UIColor.white, for: UIControlState.highlighted)
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
            backgroundColor = isHighlighted ? UIConstants.HighlightBlue : SearchViewControllerUX.SuggestionBackgroundColor
        }
    }
}
