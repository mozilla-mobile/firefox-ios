/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage

private let SuggestionBackgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.8)
private let SuggestionBorderColor = AppConstants.HighlightBlue
private let SuggestionBorderWidth: CGFloat = 1
private let SuggestionCornerRadius: CGFloat = 4
private let SuggestionFont = UIFont.systemFontOfSize(13, weight: UIFontWeightRegular)
private let SuggestionInsets = UIEdgeInsetsMake(8, 8, 8, 8)
private let SuggestionMargin: CGFloat = 8
private let SuggestionCellVerticalPadding: CGFloat = 10
private let SuggestionCellMaxRows = 2

private let PromptColor = AppConstants.PanelBackgroundColor
private let PromptFont = UIFont.systemFontOfSize(12, weight: UIFontWeightRegular)
private let PromptYesFont = UIFont.systemFontOfSize(15, weight: UIFontWeightBold)
private let PromptNoFont = UIFont.systemFontOfSize(15, weight: UIFontWeightRegular)
private let PromptInsets = UIEdgeInsetsMake(15, 12, 15, 12)
private let PromptButtonColor = UIColor(rgb: 0x007aff)

private let SearchImage = "search"
private let SearchEngineTopBorderWidth = 0.5
private let SearchImageHeight: Float = 44
private let SearchImageWidth: Float = 24

// TODO: This should use ToolbarHeight in BVC. Fix this when we create a shared theming file.
private let EngineButtonHeight: Float = 44
private let EngineButtonWidth = EngineButtonHeight * 1.4
private let EngineButtonBackgroundColor = UIColor.clearColor().CGColor


private let PromptMessage = NSLocalizedString("Turn on search suggestions?", tableName: "Search", comment: "Prompt shown before enabling provider search queries")
private let PromptYes = NSLocalizedString("Yes", tableName: "Search", comment: "For search suggestions prompt. This string should be short so it fits nicely on the prompt row.")
private let PromptNo = NSLocalizedString("No", tableName: "Search", comment: "For search suggestions prompt. This string should be short so it fits nicely on the prompt row.")

private enum SearchListSection: Int {
    case SearchSuggestions
    case BookmarksAndHistory
    static let Count = 2
}

protocol SearchViewControllerDelegate: class {
    func searchViewController(searchViewController: SearchViewController, didSelectURL url: NSURL)
    func presentSearchSettingsController()
}

class SearchViewController: SiteTableViewController, KeyboardHelperDelegate, LoaderListener {
    var searchDelegate: SearchViewControllerDelegate?

    private var suggestClient: SearchSuggestClient?

    // Views for displaying the bottom scrollable search engine list. searchEngineScrollView is the
    // scrollable container; searchEngineScrollViewContent contains the actual set of search engine buttons.
    private let searchEngineScrollView = ButtonScrollView()
    private let searchEngineScrollViewContent = UIView()

    private lazy var defaultIcon: UIImage = {
        return UIImage(named: "defaultFavicon")!
    }()

    // Cell for the suggestion flow layout. Since heightForHeaderInSection is called *before*
    // cellForRowAtIndexPath, we create the cell to find its height before it's added to the table.
    private let suggestionCell = SuggestionCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)

    private var suggestionPrompt: UIView?

    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    required override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        view.backgroundColor = AppConstants.PanelBackgroundColor
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Light))
        view.addSubview(blur)

        super.viewDidLoad()

        KeyboardHelper.defaultHelper.addDelegate(self)

        searchEngineScrollView.layer.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.8).CGColor
        searchEngineScrollView.layer.shadowRadius = 0
        searchEngineScrollView.layer.shadowOpacity = 100
        searchEngineScrollView.layer.shadowOffset = CGSize(width: 0, height: -SearchEngineTopBorderWidth)
        searchEngineScrollView.layer.shadowColor = UIColor.blackColor().colorWithAlphaComponent(0.2).CGColor
        searchEngineScrollView.clipsToBounds = false

        searchEngineScrollView.decelerationRate = UIScrollViewDecelerationRateFast
        view.addSubview(searchEngineScrollView)

        searchEngineScrollViewContent.layer.backgroundColor = UIColor.clearColor().CGColor
        searchEngineScrollView.addSubview(searchEngineScrollViewContent)

        layoutTable()
        layoutSearchEngineScrollView()

        searchEngineScrollViewContent.snp_makeConstraints { make in
            make.center.equalTo(self.searchEngineScrollView).priorityLow()
            //left-align the engines on iphones, center on ipad
            if(UIScreen.mainScreen().traitCollection.horizontalSizeClass == .Compact) {
                make.left.equalTo(self.searchEngineScrollView).priorityHigh()
            } else {
                make.left.greaterThanOrEqualTo(self.searchEngineScrollView).priorityHigh()
            }
            make.right.lessThanOrEqualTo(self.searchEngineScrollView).priorityHigh()
            make.top.equalTo(self.searchEngineScrollView)
            make.bottom.equalTo(self.searchEngineScrollView)
        }

        blur.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
        }

        suggestionCell.delegate = self
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
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

            layoutSuggestionsOptInPrompt()
        }
    }

    private func layoutSuggestionsOptInPrompt() {
        if !(searchEngines?.shouldShowSearchSuggestionsOptIn ?? false) {
            // Make sure any pending layouts are drawn so they don't get coupled
            // with the "slide up" animation below.
            view.layoutIfNeeded()

            // Set the prompt to nil so layoutTable() aligns the top of the table
            // to the top of the view. We still need a reference to the prompt so
            // we can remove it from the controller after the animation is done.
            let prompt = suggestionPrompt
            suggestionPrompt = nil
            layoutTable()

            UIView.animateWithDuration(0.2,
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
        prompt.backgroundColor = PromptColor

        let promptBottomBorder = UIView()
        promptBottomBorder.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.1)
        prompt.addSubview(promptBottomBorder)

        // Insert behind the tableView so the tableView slides on top of it
        // when the prompt is dismissed.
        view.insertSubview(prompt, belowSubview: tableView)

        suggestionPrompt = prompt

        let promptImage = UIImageView()
        promptImage.image = UIImage(named: SearchImage)
        prompt.addSubview(promptImage)

        let promptLabel = UILabel()
        promptLabel.text = PromptMessage
        promptLabel.font = PromptFont
        promptLabel.numberOfLines = 0
        promptLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        prompt.addSubview(promptLabel)

        let promptYesButton = InsetButton()
        promptYesButton.setTitle(PromptYes, forState: UIControlState.Normal)
        promptYesButton.setTitleColor(PromptButtonColor, forState: UIControlState.Normal)
        promptYesButton.titleLabel?.font = PromptYesFont
        promptYesButton.titleEdgeInsets = PromptInsets
        // If the prompt message doesn't fit, this prevents it from pushing the buttons
        // off the row and makes it wrap instead.
        promptYesButton.setContentCompressionResistancePriority(1000, forAxis: UILayoutConstraintAxis.Horizontal)
        promptYesButton.addTarget(self, action: "SELdidClickOptInYes", forControlEvents: UIControlEvents.TouchUpInside)
        prompt.addSubview(promptYesButton)

        let promptNoButton = InsetButton()
        promptNoButton.setTitle(PromptNo, forState: UIControlState.Normal)
        promptNoButton.setTitleColor(PromptButtonColor, forState: UIControlState.Normal)
        promptNoButton.titleLabel?.font = PromptNoFont
        promptNoButton.titleEdgeInsets = PromptInsets
        // If the prompt message doesn't fit, this prevents it from pushing the buttons
        // off the row and makes it wrap instead.
        promptNoButton.setContentCompressionResistancePriority(1000, forAxis: UILayoutConstraintAxis.Horizontal)
        promptNoButton.addTarget(self, action: "SELdidClickOptInNo", forControlEvents: UIControlEvents.TouchUpInside)
        prompt.addSubview(promptNoButton)

        // otherwise the label (i.e. question) is visited by VoiceOver *after* yes and no buttons
        prompt.accessibilityElements = [promptImage, promptLabel, promptYesButton, promptNoButton]

        promptImage.snp_makeConstraints { make in
            make.left.equalTo(prompt).offset(PromptInsets.left)
            make.centerY.equalTo(prompt)
        }

        promptLabel.snp_makeConstraints { make in
            make.left.equalTo(promptImage.snp_right).offset(PromptInsets.left)
            make.top.bottom.equalTo(prompt).insets(PromptInsets)
            make.right.lessThanOrEqualTo(promptYesButton.snp_left)
            return
        }

        promptNoButton.snp_makeConstraints { make in
            make.right.equalTo(prompt).insets(PromptInsets)
            make.centerY.equalTo(prompt)
        }

        promptYesButton.snp_makeConstraints { make in
            make.right.equalTo(promptNoButton.snp_leading).insets(PromptInsets)
            make.centerY.equalTo(prompt)
        }

        promptBottomBorder.snp_makeConstraints { make in
            make.trailing.leading.equalTo(self.view)
            make.top.equalTo(prompt.snp_bottom).offset(-1)
            make.height.equalTo(1)
        }

        prompt.snp_makeConstraints { make in
            make.top.leading.trailing.equalTo(self.view)
            return
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

    private func layoutTable() {
        tableView.snp_remakeConstraints { make in
            make.top.equalTo(self.suggestionPrompt?.snp_bottom ?? self.view.snp_top)
            make.leading.trailing.equalTo(self.view)
            make.bottom.equalTo(self.searchEngineScrollView.snp_top)
        }
    }

    private func reloadSearchEngines() {
        searchEngineScrollViewContent.subviews.map({ $0.removeFromSuperview() })
        var leftEdge = searchEngineScrollViewContent.snp_left

        //search settings icon
        let searchButton = UIButton()
        searchButton.setImage(UIImage(named: "quickSearch"), forState: UIControlState.Normal)
        searchButton.imageView?.contentMode = UIViewContentMode.Center
        searchButton.layer.backgroundColor = EngineButtonBackgroundColor
        searchButton.addTarget(self, action: "SELdidSelectSearchSettings", forControlEvents: UIControlEvents.TouchUpInside)
        searchButton.accessibilityLabel = String(format: NSLocalizedString("Search Settings", tableName: "Search", comment: "Label for search settings button."))

        searchButton.imageView?.snp_makeConstraints { make in
            make.width.height.equalTo(SearchImageWidth)
            return
        }

        searchEngineScrollViewContent.addSubview(searchButton)
        searchButton.snp_makeConstraints { make in
            make.width.equalTo(SearchImageWidth)
            make.height.equalTo(SearchImageHeight)
            make.left.equalTo(leftEdge).offset(SearchImageWidth/2)
            make.top.equalTo(self.searchEngineScrollViewContent)
            make.bottom.equalTo(self.searchEngineScrollViewContent)
        }

        //search engines
        leftEdge = searchButton.snp_right
        for engine in searchEngines.quickSearchEngines {
            let engineButton = UIButton()
            engineButton.setImage(engine.image, forState: UIControlState.Normal)
            engineButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            engineButton.layer.backgroundColor = EngineButtonBackgroundColor
            engineButton.addTarget(self, action: "SELdidSelectEngine:", forControlEvents: UIControlEvents.TouchUpInside)
            engineButton.accessibilityLabel = String(format: NSLocalizedString("%@ search", tableName: "Search", comment: "Label for search engine buttons. The argument corresponds to the name of the search engine."), engine.shortName)

            engineButton.imageView?.snp_makeConstraints { make in
                make.width.height.equalTo(OpenSearchEngine.PreferredIconSize)
                return
            }

            searchEngineScrollViewContent.addSubview(engineButton)
            engineButton.snp_makeConstraints { make in
                make.width.equalTo(EngineButtonWidth)
                make.height.equalTo(EngineButtonHeight)
                make.left.equalTo(leftEdge)
                make.top.equalTo(self.searchEngineScrollViewContent)
                make.bottom.equalTo(self.searchEngineScrollViewContent)
                if engine === self.searchEngines.quickSearchEngines.last {
                    make.right.equalTo(self.searchEngineScrollViewContent)
                }
            }
            leftEdge = engineButton.snp_right
        }
    }

    func SELdidSelectEngine(sender: UIButton) {
        // The UIButtons are the same cardinality and order as the array of quick search engines
        for i in 0..<searchEngineScrollViewContent.subviews.count {
            if let button = searchEngineScrollViewContent.subviews[i] as? UIButton {
                if button === sender {
                    //subtract 1 from index to account for magnifying glass accessory
                    if let url = searchEngines.quickSearchEngines[i-1].searchURLForQuery(searchQuery) {
                        searchDelegate?.searchViewController(self, didSelectURL: url)
                    }
                }
            }
        }
    }

    func SELdidSelectSearchSettings() {
        self.searchDelegate?.presentSearchSettingsController()  
    }

    func SELdidClickOptInYes() {
        searchEngines.shouldShowSearchSuggestions = true
        searchEngines.shouldShowSearchSuggestionsOptIn = false
        querySuggestClient()
        layoutSuggestionsOptInPrompt()
    }

    func SELdidClickOptInNo() {
        searchEngines.shouldShowSearchSuggestions = false
        searchEngines.shouldShowSearchSuggestionsOptIn = false
        layoutSuggestionsOptInPrompt()
    }

    func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        animateSearchEnginesWithKeyboard(state)
    }

    func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        animateSearchEnginesWithKeyboard(state)
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        // The height of the suggestions row may change, so call reloadData() to recalculate cell heights.
        coordinator.animateAlongsideTransition({ _ in
            self.tableView.reloadData()
        }, completion: nil)
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

        if searchQuery.isEmpty || !searchEngines.shouldShowSearchSuggestions {
            suggestionCell.suggestions = []
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
}

extension SearchViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let section = SearchListSection(rawValue: indexPath.section)!
        if section == SearchListSection.BookmarksAndHistory {
            if let site = data[indexPath.row] {
                if let url = NSURL(string: site.url) {
                    searchDelegate?.searchViewController(self, didSelectURL: url)
                }
            }
        }
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let currentSection = SearchListSection(rawValue: indexPath.section) {
            switch currentSection {
            case .SearchSuggestions:
                // heightForRowAtIndexPath is called *before* the cell is created, so to get the height,
                // force a layout pass first.
                suggestionCell.layoutIfNeeded()
                return suggestionCell.frame.height
            default:
                return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
            }
        }

        return 0
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
}

extension SearchViewController: UITableViewDataSource {
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch SearchListSection(rawValue: indexPath.section)! {
        case .SearchSuggestions:
            suggestionCell.imageView?.image = searchEngines.defaultEngine.image
            return suggestionCell

        case .BookmarksAndHistory:
            let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
            if let site = data[indexPath.row] {
                if let cell = cell as? TwoLineTableViewCell {
                    cell.setLines(site.title, detailText: site.url)
                    cell.imageView?.setIcon(site.icon, withPlaceholder: self.defaultIcon)
                }
            }
            return cell
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch SearchListSection(rawValue: section)! {
        case .SearchSuggestions:
            return searchEngines.shouldShowSearchSuggestions ? 1 : 0
        case .BookmarksAndHistory:
            return data.count
        }
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return SearchListSection.Count
    }
}

extension SearchViewController: SuggestionCellDelegate {
    private func suggestionCell(suggestionCell: SuggestionCell, didSelectSuggestion suggestion: String) {
        var url = URIFixup().getURL(suggestion)
        if url == nil {
            // Assume that only the default search engine can provide search suggestions.
            url = searchEngines?.defaultEngine.searchURLForQuery(suggestion)
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

private protocol SuggestionCellDelegate: class {
    func suggestionCell(suggestionCell: SuggestionCell, didSelectSuggestion suggestion: String)
}

/**
 * Cell that wraps a list of search suggestion buttons.
 */
private class SuggestionCell: UITableViewCell {
    weak var delegate: SuggestionCellDelegate?
    let container = UIView()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        isAccessibilityElement = false
        accessibilityLabel = nil
        layoutMargins = UIEdgeInsetsZero
        separatorInset = UIEdgeInsetsZero
        selectionStyle = UITableViewCellSelectionStyle.None

        container.backgroundColor = UIColor.clearColor()
        contentView.backgroundColor = UIColor.clearColor()
        backgroundColor = UIColor.clearColor()
        contentView.addSubview(container)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var suggestions: [String] = [] {
        didSet {
            for view in container.subviews {
                view.removeFromSuperview()
            }

            for suggestion in suggestions {
                let button = SuggestionButton()
                button.setTitle(suggestion, forState: UIControlState.Normal)
                button.addTarget(self, action: "SELdidSelectSuggestion:", forControlEvents: UIControlEvents.TouchUpInside)

                // If this is the first image, add the search icon.
                if container.subviews.isEmpty {
                    let image = UIImage(named: SearchImage)
                    button.setImage(image, forState: UIControlState.Normal)
                    button.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 0)
                }

                container.addSubview(button)
            }

            setNeedsLayout()
        }
    }

    @objc
    func SELdidSelectSuggestion(sender: UIButton) {
        delegate?.suggestionCell(self, didSelectSuggestion: sender.titleLabel!.text!)
    }

    private override func layoutSubviews() {
        super.layoutSubviews()

        // The left bounds of the suggestions, aligned with where text would be displayed.
        let textLeft: CGFloat = 48

        // The maximum width of the container, after which suggestions will wrap to the next line.
        let maxWidth = contentView.frame.width

        // The height of the suggestions container (minus margins), used to determine the frame.
        var height: CGFloat = 0

        var currentLeft = textLeft
        var currentTop = SuggestionCellVerticalPadding
        var currentRow = 0

        for view in container.subviews {
            let button = view as! UIButton
            var buttonSize = button.intrinsicContentSize()

            if height == 0 {
                height = buttonSize.height
            }

            var width = currentLeft + buttonSize.width + SuggestionMargin
            if width > maxWidth {
                // Only move to the next row if there's already a suggestion on this row.
                // Otherwise, the suggestion is too big to fit and will be resized below.
                if currentLeft > textLeft {
                    currentRow++
                    if currentRow >= SuggestionCellMaxRows {
                        // Don't draw this button if it doesn't fit on the row.
                        button.frame = CGRectZero
                        continue
                    }

                    currentLeft = textLeft
                    currentTop += buttonSize.height + SuggestionMargin
                    height += buttonSize.height + SuggestionMargin
                    width = currentLeft + buttonSize.width + SuggestionMargin
                }

                // If the suggestion is too wide to fit on its own row, shrink it.
                if width > maxWidth {
                    buttonSize.width = maxWidth - currentLeft - SuggestionMargin
                }
            }

            button.frame = CGRectMake(currentLeft, currentTop, buttonSize.width, buttonSize.height)
            currentLeft += buttonSize.width + SuggestionMargin
        }

        frame.size.height = height + 2 * SuggestionCellVerticalPadding
        contentView.frame = frame
        container.frame = frame

        let imageSize = CGFloat(OpenSearchEngine.PreferredIconSize)
        let imageX = (48 - imageSize) / 2
        let imageY = (frame.size.height - imageSize) / 2
        imageView!.frame = CGRectMake(imageX, imageY, imageSize, imageSize)
    }
}

/**
 * Rounded search suggestion button that highlights when selected.
 */
private class SuggestionButton: InsetButton {
    override init(frame: CGRect) {
        super.init(frame: frame)

        setTitleColor(AppConstants.HighlightBlue, forState: UIControlState.Normal)
        setTitleColor(UIColor.whiteColor(), forState: UIControlState.Highlighted)
        titleLabel?.font = SuggestionFont
        backgroundColor = SuggestionBackgroundColor
        layer.borderColor = SuggestionBorderColor.CGColor
        layer.borderWidth = SuggestionBorderWidth
        layer.cornerRadius = SuggestionCornerRadius
        contentEdgeInsets = SuggestionInsets

        accessibilityHint = NSLocalizedString("Searches for the suggestion", comment: "Accessibility hint describing the action performed when a search suggestion is clicked")
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    override var highlighted: Bool {
        didSet {
            backgroundColor = highlighted ? AppConstants.HighlightBlue : SuggestionBackgroundColor
        }
    }
}
