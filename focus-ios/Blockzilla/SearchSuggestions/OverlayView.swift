/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import Glean
import UIHelpers

protocol OverlayViewDelegate: AnyObject {
    func overlayViewDidTouchEmptyArea(_ overlayView: OverlayView)
    func overlayViewDidPressSettings(_ overlayView: OverlayView)
    func overlayView(_ overlayView: OverlayView, didSearchForQuery query: String)
    func overlayView(_ overlayView: OverlayView, didSubmitText text: String)
    func overlayView(_ overlayView: OverlayView, didSearchOnPage query: String)
    func overlayView(_ overlayView: OverlayView, didAddToAutocomplete query: String)
    func overlayView(_ overlayView: OverlayView, didTapArrowText text: String)
}

class IndexedInsetButton: InsetButton {
    private var index: Int = 0
    func setIndex(_ i: Int) {
        index = i
    }
    func getIndex() -> Int {
        return index
    }
}

class OverlayView: UIView {
    weak var delegate: OverlayViewDelegate?
    private let addToAutocompleteButton = InsetButton()
    private var searchQuery = ""
    private var searchSuggestions = [String]()
    private var searchButtonGroup = [IndexedInsetButton]()
    private let copyButton = UIButton()
    private let findInPageButton = InsetButton()
    private let searchSuggestionsPrompt = SearchSuggestionsPromptView()
    private let topBorder = UIView()
    private let lastSeparator = UIView()
    private var separatorGroup = [UIView]()
    private var arrowButtons = [UIButton]()
    private let maxNumOfSuggestions = UIDevice.current.isSmallDevice() ? UIConstants.layout.smallDeviceMaxNumSuggestions : UIConstants.layout.largeDeviceMaxNumSuggestions
    public var currentURL = ""

    var isIpadView = false {
        didSet {
            searchSuggestionsPrompt.isIpadView = isIpadView
            updateLayout(for: isIpadView)
            updateSearchButtons()
        }
    }

    private var shouldShowFindInPage =  false {
        didSet {
            updateDesign(shouldShowFindInPage)
        }
    }

    init() {
        super.init(frame: CGRect.zero)
        KeyboardHelper.defaultHelper.addDelegate(delegate: self)

        searchSuggestionsPrompt.clipsToBounds = true
        searchSuggestionsPrompt.accessibilityIdentifier = "SearchSuggestionsPromptView"
        addSubview(searchSuggestionsPrompt)

        searchSuggestionsPrompt.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(safeAreaLayoutGuide)
        }

        for i in 0..<maxNumOfSuggestions {
            makeSearchSuggestionButton(atIndex: i)
        }

        topBorder.backgroundColor = .grey90.withAlphaComponent(0.4)
        addSubview(topBorder)

        let padding = UIConstants.layout.searchButtonInset
        let attributedString = NSMutableAttributedString(string: UIConstants.strings.addToAutocompleteButton, attributes: [.foregroundColor: UIColor.grey10])

        addToAutocompleteButton.titleLabel?.font = .body16
        addToAutocompleteButton.titleEdgeInsets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        addToAutocompleteButton.titleLabel?.lineBreakMode = .byTruncatingTail
        addToAutocompleteButton.setImage(#imageLiteral(resourceName: "icon_add_to_autocomplete"), for: .normal)
        addToAutocompleteButton.setImage(#imageLiteral(resourceName: "icon_add_to_autocomplete"), for: .highlighted)
        addToAutocompleteButton.setAttributedTitle(attributedString, for: .normal)
        addToAutocompleteButton.addTarget(self, action: #selector(didPressAddToAutocomplete), for: .touchUpInside)
        addToAutocompleteButton.accessibilityIdentifier = "AddToAutocomplete.button"
        addToAutocompleteButton.backgroundColor = .ink90
        setUpOverlayButton(button: addToAutocompleteButton)
        addSubview(addToAutocompleteButton)

        addToAutocompleteButton.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(safeAreaLayoutGuide)
        }

        findInPageButton.isHidden = true
        shouldShowFindInPage = false
        findInPageButton.titleLabel?.font = .body16
        findInPageButton.titleEdgeInsets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        findInPageButton.titleLabel?.lineBreakMode = .byTruncatingTail
        findInPageButton.addTarget(self, action: #selector(didPressFindOnPage), for: .touchUpInside)
        findInPageButton.accessibilityIdentifier = "FindInPageBar.button"

        if UIView.userInterfaceLayoutDirection(for: findInPageButton.semanticContentAttribute) == .rightToLeft {
            findInPageButton.contentHorizontalAlignment = .right
        } else {
            findInPageButton.contentHorizontalAlignment = .left
        }
        addSubview(findInPageButton)

        lastSeparator.isHidden = true
        addSubview(lastSeparator)

        copyButton.titleLabel?.font = .body16
        copyButton.titleEdgeInsets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        copyButton.titleLabel?.lineBreakMode = .byTruncatingTail
        copyButton.backgroundColor = .ink90
        if UIView.userInterfaceLayoutDirection(for: copyButton.semanticContentAttribute) == .rightToLeft {
            copyButton.contentHorizontalAlignment = .right
        } else {
            copyButton.contentHorizontalAlignment = .left
        }
        copyButton.addTarget(self, action: #selector(didPressCopy), for: .touchUpInside)
        addSubview(copyButton)

        updateLayout(for: isIpadView)
    }

    private func updateLayout(for iPadView: Bool) {
        searchSuggestionsPrompt.backgroundColor = iPadView ? .clear : .ink90

        topBorder.snp.remakeConstraints { make in
            make.top.equalTo(searchSuggestionsPrompt.snp.bottom)
            make.leading.trailing.equalTo(safeAreaLayoutGuide)
            make.height.equalTo(iPadView ? 0.5 : 0)
        }

        self.searchButtonGroup[0].snp.remakeConstraints { make in
            make.top.equalTo(topBorder.snp.bottom)
            if iPadView {
                make.width.equalTo(searchSuggestionsPrompt).multipliedBy(UIConstants.layout.suggestionViewWidthMultiplier)
                make.centerX.equalToSuperview()
            } else {
                make.width.equalTo(safeAreaLayoutGuide)
                make.leading.trailing.equalTo(safeAreaLayoutGuide)
            }
        }

        for i in 1..<maxNumOfSuggestions {
            self.searchButtonGroup[i].snp.removeConstraints()
            self.searchButtonGroup[i].snp.makeConstraints { make in
                make.top.equalTo(searchButtonGroup[i-1].snp.bottom)
                make.leading.trailing.equalTo(iPadView ? searchButtonGroup[i-1] :safeAreaLayoutGuide)
                make.height.equalTo(UIConstants.layout.overlayButtonHeight)
            }

            self.separatorGroup[i - 1].snp.remakeConstraints { make in
                make.height.equalTo(0.5)
                make.top.equalTo(searchButtonGroup[i - 1].snp.bottom)
                make.leading.equalTo(searchButtonGroup[i].snp.leading).inset(52)
                make.trailing.equalTo(searchButtonGroup[i].snp.trailing)
            }

            self.arrowButtons[i - 1].snp.remakeConstraints { make in
                make.height.width.equalTo(UIConstants.layout.searchSuggestionsArrowButtonWidth)
                make.trailing.equalTo(searchButtonGroup[i].snp.trailing).inset(12)
                make.centerY.equalTo(searchButtonGroup[i])
            }
        }

        findInPageButton.backgroundColor = iPadView ? .secondarySystemBackground.withAlphaComponent(0.95) : .foundation

        remakeConstraintsForFindInPage()

        if iPadView {
            findInPageButton.layer.cornerRadius = UIConstants.layout.suggestionViewCornerRadius
            findInPageButton.clipsToBounds =  true
            findInPageButton.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
            lastSeparator.backgroundColor = .systemGray
            topBorder.backgroundColor = .clear
        } else {
            searchButtonGroup.first?.layer.cornerRadius = 0
            findInPageButton.layer.cornerRadius = 0
            lastSeparator.backgroundColor = .clear
            topBorder.backgroundColor =  .grey90.withAlphaComponent(0.4)
        }
        setColorstToSearchButtons()
    }

    private func makeSearchSuggestionButton(atIndex i: Int) {
        let searchButton = IndexedInsetButton()
        searchButton.isHidden = true
        searchButton.accessibilityIdentifier = "OverlayView.searchButton"
        searchButton.setImage(#imageLiteral(resourceName: "icon_searchfor"), for: .normal)
        searchButton.setImage(#imageLiteral(resourceName: "icon_searchfor"), for: .highlighted)
        searchButton.backgroundColor = .above
        searchButton.titleLabel?.font = .body16

        searchButton.setIndex(i)
        setUpOverlayButton(button: searchButton)
        searchButton.addTarget(self, action: #selector(didPressSearch(sender:)), for: .touchUpInside)
        self.searchButtonGroup.append(searchButton)
        addSubview(searchButton)

        if i != 0 {
            let separator = UIView()
            separator.backgroundColor = .systemGray
            self.separatorGroup.append(separator)
            searchButton.addSubview(separator)

            let arrowButton = UIButton()
            arrowButton.setImage(#imageLiteral(resourceName: "icon_go_to_suggestion"), for: .normal)
            arrowButton.addTarget(self, action: #selector(didPressArrowButton(sender:)), for: .touchUpInside)
            self.arrowButtons.append(arrowButton)
            searchButton.addSubview(arrowButton)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setColorstToSearchButtons() {
        for button in searchButtonGroup {
            button.backgroundColor = isIpadView ? .secondarySystemBackground.withAlphaComponent(0.95) : .foundation
            button.highlightedBackgroundColor = .searchSuggestionButtonHighlight
        }
    }

    func setUpOverlayButton (button: InsetButton) {
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        if UIView.userInterfaceLayoutDirection(for: button.semanticContentAttribute) == .rightToLeft {
            button.contentHorizontalAlignment = .right
        } else {
            button.contentHorizontalAlignment = .left
        }

        let padding = UIConstants.layout.searchButtonInset
        button.imageEdgeInsets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        if UIView.userInterfaceLayoutDirection(for: button.semanticContentAttribute) == .rightToLeft {
            button.titleEdgeInsets = UIEdgeInsets(top: padding, left: padding + UIConstants.layout.searchSuggestionsArrowButtonWidth, bottom: padding, right: padding * 2)
        } else {
            button.titleEdgeInsets = UIEdgeInsets(top: padding, left: padding * 2, bottom: padding, right: UIConstants.layout.searchSuggestionsArrowButtonWidth + padding)
        }
    }

    /**
     
     Localize and style 'phrase' text for use as a button title.
     
     - Parameter phrase: The phrase text for a button title
     - Parameter localizedStringFormat: The localization format string to apply
     
     - Returns: An NSAttributedString with `phrase` localized and styled appropriately.
     
     */
	func getAttributedButtonTitle(phrase: String, localizedStringFormat: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: localizedStringFormat, attributes: [.foregroundColor: UIColor.primaryText])
		let phraseString = NSAttributedString(string: phrase, attributes: [.font: UIFont.body17,
                                                                           .foregroundColor: UIColor.primaryText])
		if phrase != searchQuery {
			let searchString = NSAttributedString(string: searchQuery, attributes: [.font: UIFont.body17,
                                                                                    .foregroundColor: UIColor.primaryText])
			// split suggestion into searchQuery and suggested part
			let suggestion = phrase.components(separatedBy: searchQuery)
			// suggestion was split
			if suggestion.count > 1 {
                let restOfSuggestion = NSAttributedString(string: suggestion[1], attributes: [.font: UIFont.body17,
                                                                                              .foregroundColor: UIColor.primaryText])
				attributedString.append(searchString)
				attributedString.append(restOfSuggestion)
				return attributedString
			}
		}
		guard let range = attributedString.string.range(of: "%@") else { return phraseString }
		let replaceRange = NSRange(range, in: attributedString.string)
		attributedString.replaceCharacters(in: replaceRange, with: phraseString)
		return attributedString
	}

    func setAttributedButtonTitle(phrase: String, button: InsetButton, localizedStringFormat: String) {
        let attributedString = getAttributedButtonTitle(phrase: phrase,
                                                        localizedStringFormat: localizedStringFormat)
        button.setAttributedTitle(attributedString, for: .normal)
    }

    private func setURLicon(button: InsetButton) {
            button.setImage(#imageLiteral(resourceName: "icon_searchfor"), for: .normal)
            button.setImage(#imageLiteral(resourceName: "icon_searchfor"), for: .highlighted)
    }

    func setSearchQuery(suggestions: [String], hideFindInPage: Bool, hideAddToComplete: Bool) {
        searchQuery = suggestions[0]
        searchSuggestions = searchQuery.isEmpty ? [] : suggestions
        let searchSuggestionsPromptHidden = UserDefaults.standard.bool(forKey: SearchSuggestionsPromptView.respondedToSearchSuggestionsPrompt) || searchQuery.isEmpty
        DispatchQueue.main.async {
            self.updateSearchSuggestionsPrompt(hidden: searchSuggestionsPromptHidden)
            // Hide the autocomplete button on home screen and when the user is typing
            self.addToAutocompleteButton.isHidden = true
            if !self.isIpadView {
                self.topBorder.backgroundColor =  searchSuggestionsPromptHidden ? .grey90.withAlphaComponent(0.4) : UIColor(rgb: 0x42455A)
            }
            self.updateSearchButtons()
            let lastSearchButtonIndex = min(self.searchSuggestions.count, self.searchButtonGroup.count) - 1
            self.updateFindInPageConstraints(
                findInPageHidden: hideFindInPage,
                lastSearchButtonIndex: lastSearchButtonIndex
            )
            self.updateCopyConstraints(
                copyButtonHidden: true,
                findInPageHidden: hideFindInPage,
                lastSearchButtonIndex: lastSearchButtonIndex
            )
        }
    }

    private func updateSearchButtons() {
        for index in 0..<self.searchButtonGroup.count {
            let hasSuggestionInIndex = index < self.searchSuggestions.count
            self.searchButtonGroup[index].isHidden = !hasSuggestionInIndex
            if hasSuggestionInIndex {
                self.setAttributedButtonTitle(
                    phrase: self.searchSuggestions[index],
                    button: self.searchButtonGroup[index],
                    localizedStringFormat: Settings.getToggle(.enableSearchSuggestions) ? "" : UIConstants.strings.searchButton
                )
                self.setURLicon(button: self.searchButtonGroup[index])
            }
        }
    }

    private func updateFindInPageConstraints(findInPageHidden: Bool, lastSearchButtonIndex: Int) {
        findInPageButton.isHidden = findInPageHidden
        shouldShowFindInPage = !findInPageHidden

        findInPageButton.snp.remakeConstraints { (make) in
            if isIpadView {
                make.width.equalTo(searchSuggestionsPrompt).multipliedBy(UIConstants.layout.suggestionViewWidthMultiplier)
                if let firstButton = searchButtonGroup.first {
                    make.leading.equalTo(firstButton.snp.leading)
                } else {
                    make.leading.equalTo(searchSuggestionsPrompt.snp.leading)
                }
            } else {
                make.leading.trailing.equalTo(safeAreaLayoutGuide)
            }
            if lastSearchButtonIndex >= 0 && !searchButtonGroup[lastSearchButtonIndex].isHidden {
                make.top.equalTo(searchButtonGroup[lastSearchButtonIndex].snp.bottom)
            } else {
                make.top.equalTo(topBorder.snp.bottom)
            }
            make.height.equalTo(UIConstants.layout.overlayButtonHeight)
        }

        if isIpadView {
            lastSeparator.snp.makeConstraints { make in
                make.height.equalTo(0.5)
                make.bottom.equalTo(findInPageButton.snp.top)
                make.leading.equalTo(findInPageButton.snp.leading).inset(52)
                make.trailing.equalTo(findInPageButton.snp.trailing)
            }
            lastSeparator.isHidden = !shouldShowFindInPage
        }

        self.setAttributedButtonTitle(phrase: self.searchQuery, button: self.findInPageButton, localizedStringFormat: UIConstants.strings.findInPageButton)
    }

    private func updateCopyConstraints(copyButtonHidden: Bool, findInPageHidden: Bool, lastSearchButtonIndex: Int) {
        copyButton.isHidden = copyButtonHidden

        if copyButtonHidden {
            return
        }

        copyButton.snp.remakeConstraints { make in
            if !findInPageHidden {
                make.top.equalTo(findInPageButton.snp.bottom)
            } else if lastSearchButtonIndex >= 0 && !searchButtonGroup[lastSearchButtonIndex].isHidden {
                make.top.equalTo(searchButtonGroup[lastSearchButtonIndex].snp.bottom)
            } else {
                make.top.equalTo(topBorder.snp.bottom)
            }

            make.leading.trailing.equalTo(safeAreaLayoutGuide)
            make.height.equalTo(UIConstants.layout.overlayButtonHeight)
        }
    }

    private func updateDesign(_ shouldShowFindInPage: Bool) {
        guard isIpadView  else {
            return
        }
        topBorder.backgroundColor = .clear
        searchButtonGroup.last?.layer.cornerRadius = UIConstants.layout.suggestionViewCornerRadius
        searchButtonGroup.last?.clipsToBounds =  true
        searchButtonGroup.first?.layer.cornerRadius = UIConstants.layout.suggestionViewCornerRadius
        searchButtonGroup.first?.clipsToBounds = true

        let searchSuggestionsPromptHidden = UserDefaults.standard.bool(forKey: SearchSuggestionsPromptView.respondedToSearchSuggestionsPrompt) || searchQuery.isEmpty

        let topCorners: CACornerMask = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        let bottomCorners: CACornerMask = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        let allCorners: CACornerMask = [.layerMaxXMinYCorner, .layerMinXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]

        var firstSearchButtonMaskedCorners = topCorners

        if !searchSuggestionsPromptHidden {
            firstSearchButtonMaskedCorners = findInPageButton.isHidden ? bottomCorners : []
        } else if searchSuggestions.count == 1 {
            firstSearchButtonMaskedCorners = findInPageButton.isHidden ? allCorners : topCorners
        }

        searchButtonGroup.first?.layer.maskedCorners = firstSearchButtonMaskedCorners
        searchButtonGroup.last?.layer.maskedCorners = findInPageButton.isHidden ? bottomCorners : []
    }

    private func remakeConstraintsForFindInPage() {
        findInPageButton.snp.remakeConstraints { (make) in
            if isIpadView {
                make.width.equalTo(searchSuggestionsPrompt).multipliedBy(UIConstants.layout.suggestionViewWidthMultiplier)
                if let firstButton = searchButtonGroup.first {
                    make.leading.equalTo(firstButton.snp.leading)
                } else {
                    make.leading.equalTo(searchSuggestionsPrompt.snp.leading)
                }
            } else {
                make.leading.trailing.equalTo(safeAreaLayoutGuide)
            }
            if let lastSearchButton = searchButtonGroup.last {
                let searchButtonCount = searchButtonGroup.count
                if searchButtonCount >= 0 && !lastSearchButton.isHidden {
                    make.top.equalTo(lastSearchButton.snp.bottom)
                } else {
                    make.top.equalTo(topBorder.snp.bottom)
                }
            }
            make.height.equalTo(UIConstants.layout.overlayButtonHeight)
        }
    }

    @objc
    private func didPressArrowButton(sender: UIButton) {
        if let index = arrowButtons.firstIndex(of: sender) {
            delegate?.overlayView(self, didTapArrowText: searchSuggestions[index + 1])
            GleanMetrics
                .SearchSuggestions
                .autocompleteArrowTapped
                .record()
        }
    }

    @objc
    private func didPressSearch(sender: IndexedInsetButton) {
        // Safeguard against a potential update of searchSuggestions causing this index to no longer exist
        let immutableSearchSuggestions = searchSuggestions
        delegate?.overlayView(self, didSearchForQuery: immutableSearchSuggestions[sender.getIndex()])

        if !Settings.getToggle(.enableSearchSuggestions) { return }
        let activeSearchEngine = SearchEngineManager(prefs: UserDefaults.standard).activeEngine
        let defaultSearchEngineProvider = activeSearchEngine.isCustom ? "custom" : activeSearchEngine.name
        if sender.getIndex() == 0 {
            GleanMetrics
                .SearchSuggestions
                .searchTapped
                .record(
                    GleanMetrics
                        .SearchSuggestions
                        .SearchTappedExtra(engineName: defaultSearchEngineProvider)
                )
        } else {
            GleanMetrics
                .SearchSuggestions
                .suggestionTapped
                .record(
                    GleanMetrics
                        .SearchSuggestions
                        .SuggestionTappedExtra(engineName: defaultSearchEngineProvider)
                )
        }
    }
    @objc
    private func didPressCopy() {
        delegate?.overlayView(self, didSubmitText: UIPasteboard.general.string!)
    }
    @objc
    private func didPressFindOnPage() {
        delegate?.overlayView(self, didSearchOnPage: searchQuery)
    }
    @objc
    private func didPressAddToAutocomplete() {
        delegate?.overlayView(self, didAddToAutocomplete: currentURL)
    }
    @objc
    private func didPressSettings() {
        delegate?.overlayViewDidPressSettings(self)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        delegate?.overlayViewDidTouchEmptyArea(self)
    }

    func dismiss() {
        setSearchQuery(suggestions: [""], hideFindInPage: true, hideAddToComplete: true)
        self.isUserInteractionEnabled = false
        animateHidden(true, duration: UIConstants.layout.overlayAnimationDuration) {
            self.isUserInteractionEnabled = true
        }
    }

    func present(isOnHomeView: Bool) {
        setSearchQuery(suggestions: [""], hideFindInPage: true, hideAddToComplete: false || isOnHomeView)
        self.isUserInteractionEnabled = false
        copyButton.isHidden = false
        addToAutocompleteButton.isHidden = true
        self.backgroundColor = isOnHomeView ? .clear : .scrim.withAlphaComponent(0.48)
        animateHidden(false, duration: UIConstants.layout.overlayAnimationDuration) {
            self.isUserInteractionEnabled = true
        }
    }

    func setSearchSuggestionsPromptViewDelegate(delegate: SearchSuggestionsPromptViewDelegate) {
        searchSuggestionsPrompt.delegate = delegate
    }

    func updateSearchSuggestionsPrompt(hidden: Bool) {
        searchSuggestionsPrompt.isHidden = hidden
        updateSearchButtons()
        searchSuggestionsPrompt.snp.remakeConstraints { make in
            make.top.leading.trailing.equalTo(safeAreaLayoutGuide)

            if hidden {
                make.height.equalTo(0)
            }
        }
    }
}

extension OverlayView: KeyboardHelperDelegate {
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {}
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {}
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {}
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidHideWithState state: KeyboardState) {}
}
