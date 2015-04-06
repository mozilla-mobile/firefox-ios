/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage

private let SuggestionBackgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
private let SuggestionBorderColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1)
private let SuggestionBorderWidth: CGFloat = 0.5
private let SuggestionCornerRadius: CGFloat = 2
private let SuggestionFont = UIFont(name: UIAccessibilityIsBoldTextEnabled() ? "HelveticaNeue-Medium" : "HelveticaNeue", size: 12)
private let SuggestionInsets = UIEdgeInsetsMake(5, 5, 5, 5)
private let SuggestionMargin: CGFloat = 4
private let SuggestionCellVerticalPadding: CGFloat = 8
private let SuggestionCellMaxRows = 2

private let PromptColor = UIColor(rgb: 0xeef0f3)
private let PromptFont = UIFont(name: UIAccessibilityIsBoldTextEnabled() ? "HelveticaNeue-Medium" : "HelveticaNeue", size: 12)
private let PromptYesFont = UIFont(name: "HelveticaNeue-Bold", size: 15)
private let PromptNoFont = UIFont(name: UIAccessibilityIsBoldTextEnabled() ? "HelveticaNeue-Medium" : "HelveticaNeue", size: 15)
private let PromptInsets = UIEdgeInsetsMake(15, 12, 15, 12)
private let PromptButtonColor = UIColor(rgb: 0x007aff)

private let SearchImage = "search"

// searchEngineScrollViewContent is the button container. It has a gray background color,
// so with insets applied to its buttons, the background becomes the button border.
private let EngineButtonInsets = UIEdgeInsetsMake(0.5, 0.5, 0.5, 0.5)

// TODO: This should use ToolbarHeight in BVC. Fix this when we create a shared theming file.
private let EngineButtonHeight: Float = 44
private let EngineButtonWidth = EngineButtonHeight * 1.5

private let PromptMessage = NSLocalizedString("Turn on search suggestions?", tableName: "search", comment: "Prompt shown before enabling provider search queries")
private let PromptYes = NSLocalizedString("Yes", tableName: "search", comment: "For search suggestions prompt. This string should be short so it fits nicely on the prompt row.")
private let PromptNo = NSLocalizedString("No", tableName: "search", comment: "For search suggestions prompt. This string should be short so it fits nicely on the prompt row.")

private enum SearchListSection: Int {
    case SearchSuggestions
    case BookmarksAndHistory
    static let Count = 2
}

protocol SearchViewControllerDelegate: class {
    func searchViewController(searchViewController: SearchViewController, didSelectURL url: NSURL)
}

class SearchViewController: SiteTableViewController, KeyboardHelperDelegate, LoaderListener {
    var searchDelegate: SearchViewControllerDelegate?

    private var suggestClient: SearchSuggestClient?

    // Views for displaying the bottom scrollable search engine list. searchEngineScrollView is the
    // scrollable container; searchEngineScrollViewContent contains the actual set of search engine buttons.
    private let searchEngineScrollView = ButtonScrollView()
    private let searchEngineScrollViewContent = UIView()

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
        super.viewDidLoad()

        KeyboardHelper.defaultHelper.addDelegate(self)

        searchEngineScrollView.layer.backgroundColor = tableView.backgroundColor?.CGColor
        searchEngineScrollView.decelerationRate = UIScrollViewDecelerationRateFast
        view.addSubview(searchEngineScrollView)

        searchEngineScrollViewContent.layer.backgroundColor = tableView.separatorColor.CGColor
        searchEngineScrollView.addSubview(searchEngineScrollViewContent)

        layoutTable()
        layoutSearchEngineScrollView()

        searchEngineScrollViewContent.snp_makeConstraints { make in
            make.center.equalTo(self.searchEngineScrollView).priorityLow()
            make.left.greaterThanOrEqualTo(self.searchEngineScrollView).priorityHigh()
            make.right.lessThanOrEqualTo(self.searchEngineScrollView).priorityHigh()
            make.top.bottom.equalTo(self.searchEngineScrollView)
        }

        suggestionCell.delegate = self
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
            view.layoutIfNeeded()
            suggestionPrompt = nil
            layoutTable()
            UIView.animateWithDuration(0.2,
                animations: {
                    self.view.layoutIfNeeded()
                },
                completion: { _ in
                    self.suggestionPrompt?.removeFromSuperview()
                    return
                })
            return
        }

        let prompt = UIView()
        prompt.backgroundColor = PromptColor
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
        for engine in searchEngines.quickSearchEngines {
            let engineButton = UIButton()
            engineButton.setImage(engine.image, forState: UIControlState.Normal)
            engineButton.layer.backgroundColor = UIColor.whiteColor().CGColor
            engineButton.addTarget(self, action: "SELdidSelectEngine:", forControlEvents: UIControlEvents.TouchUpInside)
            engineButton.accessibilityLabel = String(format: NSLocalizedString("%@ search", comment: "Label for search engine buttons. The argument corresponds to the name of the search engine."), engine.shortName)

            searchEngineScrollViewContent.addSubview(engineButton)
            engineButton.snp_makeConstraints { make in
                make.width.equalTo(EngineButtonWidth)
                make.height.equalTo(EngineButtonHeight)
                make.left.equalTo(leftEdge).offset(EngineButtonInsets.left)
                make.top.bottom.equalTo(self.searchEngineScrollViewContent).insets(EngineButtonInsets)
                if engine === self.searchEngines.quickSearchEngines.last {
                    make.right.equalTo(self.searchEngineScrollViewContent).offset(-EngineButtonInsets.right)
                }
            }
            leftEdge = engineButton.snp_right
        }
    }

    func SELdidSelectEngine(sender: UIButton) {
        // The UIButtons are the same cardinality and order as the array of quick search engines.
        for i in 0..<searchEngineScrollViewContent.subviews.count {
            if let button = searchEngineScrollViewContent.subviews[i] as? UIButton {
                if button === sender {
                    if let url = searchEngines.quickSearchEngines[i].searchURLForQuery(searchQuery) {
                        searchDelegate?.searchViewController(self, didSelectURL: url)
                    }
                }
            }
        }
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

    func loader(dataLoaded data: Cursor) {
        self.data = data
        tableView.reloadData()
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let section = SearchListSection(rawValue: indexPath.section)!
        if section == SearchListSection.BookmarksAndHistory {
            if let site = data[indexPath.row] as? Site {
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
            if let site = data[indexPath.row] as? Site {
                if let cell = cell as? TwoLineTableViewCell {
                    cell.setLines(site.title, detailText: site.url)
                    if let img = site.icon {
                        let imgUrl = NSURL(string: img.url)
                        cell.imageView?.sd_setImageWithURL(imgUrl, placeholderImage: self.profile.favicons.defaultIcon)
                    } else {
                        cell.imageView?.image = self.profile.favicons.defaultIcon
                    }
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

        // The left bounds of the suggestions align with where text would be displayed.
        let textLeft: CGFloat = 44

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

        let imageY = (frame.size.height - 24) / 2
        imageView!.frame = CGRectMake(10, imageY, 24, 24)
    }
}

/**
 * Rounded search suggestion button that highlights when selected.
 */
private class SuggestionButton: InsetButton {
    override init(frame: CGRect) {
        super.init(frame: frame)

        setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Normal)
        titleLabel?.font = SuggestionFont
        backgroundColor = SuggestionBackgroundColor
        layer.borderColor = SuggestionBackgroundColor.CGColor
        layer.borderWidth = SuggestionBorderWidth
        layer.cornerRadius = SuggestionCornerRadius
        contentEdgeInsets = SuggestionInsets
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    override var highlighted: Bool {
        didSet {
            backgroundColor = highlighted ? UIColor.grayColor() : SuggestionBackgroundColor
        }
    }
}
