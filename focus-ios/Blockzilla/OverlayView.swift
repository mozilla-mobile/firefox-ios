/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import Telemetry

protocol OverlayViewDelegate: class {
    func overlayViewDidTouchEmptyArea(_ overlayView: OverlayView)
    func overlayViewDidPressSettings(_ overlayView: OverlayView)
    func overlayView(_ overlayView: OverlayView, didSearchForQuery query: String)
    func overlayView(_ overlayView: OverlayView, didSubmitText text: String)
    func overlayView(_ overlayView: OverlayView, didSearchOnPage query: String)
    func overlayView(_ overlayView: OverlayView, didAddToAutocomplete query: String)
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
    private let searchButton = InsetButton()
    private let addToAutocompleteButton = InsetButton()
    private var presented = false
    private var searchQuery = ""
    private var searchSuggestions = [String]()
    private var searchButtonGroup = [IndexedInsetButton]()
    private let copyButton = UIButton()
    private let findInPageButton = InsetButton()
    private let searchSuggestionsPrompt = SearchSuggestionsPromptView()
    private let topBorder = UIView()
    private let maxNumOfSuggestions = UIDevice.current.isSmallDevice() ? UIConstants.layout.smallDeviceMaxNumSuggestions : UIConstants.layout.largeDeviceMaxNumSuggestions
    public var currentURL = ""

    init() {
        super.init(frame: CGRect.zero)
        KeyboardHelper.defaultHelper.addDelegate(delegate: self)

        searchSuggestionsPrompt.backgroundColor = UIConstants.colors.background
        searchSuggestionsPrompt.clipsToBounds = true
        searchSuggestionsPrompt.accessibilityIdentifier = "SearchSuggestionsPromptView"
        addSubview(searchSuggestionsPrompt)

        searchSuggestionsPrompt.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(safeAreaLayoutGuide)
        }

        for i in 0..<maxNumOfSuggestions {
            makeSearchSuggestionButton(atIndex: i)
        }

        topBorder.backgroundColor = UIConstants.Photon.Grey90.withAlphaComponent(0.4)
        addSubview(topBorder)

        topBorder.snp.makeConstraints { make in
            make.top.equalTo(searchSuggestionsPrompt.snp.bottom)
            make.leading.trailing.equalTo(safeAreaLayoutGuide)
            make.height.equalTo(1)
        }

        self.searchButtonGroup[0].snp.makeConstraints { make in
            make.top.equalTo(topBorder.snp.bottom)
            make.leading.trailing.equalTo(safeAreaLayoutGuide)
        }
        for i in 1..<maxNumOfSuggestions {
            self.searchButtonGroup[i].snp.makeConstraints { make in
                make.top.equalTo(searchButtonGroup[i - 1].snp.bottom)
                make.leading.trailing.equalTo(safeAreaLayoutGuide)
                make.height.equalTo(UIConstants.layout.overlayButtonHeight)
            }
        }

        let padding = UIConstants.layout.searchButtonInset
        let attributedString = NSMutableAttributedString(string: UIConstants.strings.addToAutocompleteButton, attributes: [.foregroundColor: UIConstants.Photon.Grey10])

        addToAutocompleteButton.titleLabel?.font = UIConstants.fonts.copyButton
        addToAutocompleteButton.titleEdgeInsets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        addToAutocompleteButton.titleLabel?.lineBreakMode = .byTruncatingTail
        addToAutocompleteButton.setImage(#imageLiteral(resourceName: "icon_add_to_autocomplete"), for: .normal)
        addToAutocompleteButton.setImage(#imageLiteral(resourceName: "icon_add_to_autocomplete"), for: .highlighted)
        addToAutocompleteButton.setAttributedTitle(attributedString, for: .normal)
        addToAutocompleteButton.addTarget(self, action: #selector(didPressAddToAutocomplete), for: .touchUpInside)
        addToAutocompleteButton.accessibilityIdentifier = "AddToAutocomplete.button"
        addToAutocompleteButton.backgroundColor = UIConstants.colors.background
        setUpOverlayButton(button: addToAutocompleteButton)
        addSubview(addToAutocompleteButton)

        addToAutocompleteButton.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(safeAreaLayoutGuide)
        }

        findInPageButton.isHidden = true
        findInPageButton.titleLabel?.font = UIConstants.fonts.copyButton
        findInPageButton.titleEdgeInsets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        findInPageButton.titleLabel?.lineBreakMode = .byTruncatingTail
        findInPageButton.addTarget(self, action: #selector(didPressFindOnPage), for: .touchUpInside)
        findInPageButton.accessibilityIdentifier = "FindInPageBar.button"
        findInPageButton.backgroundColor = UIConstants.colors.background
        if UIView.userInterfaceLayoutDirection(for: findInPageButton.semanticContentAttribute) == .rightToLeft {
            findInPageButton.contentHorizontalAlignment = .right
        } else {
            findInPageButton.contentHorizontalAlignment = .left
        }
        addSubview(findInPageButton)

        copyButton.titleLabel?.font = UIConstants.fonts.copyButton
        copyButton.titleEdgeInsets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        copyButton.titleLabel?.lineBreakMode = .byTruncatingTail
        copyButton.backgroundColor = UIConstants.colors.background
        if UIView.userInterfaceLayoutDirection(for: copyButton.semanticContentAttribute) == .rightToLeft {
            copyButton.contentHorizontalAlignment = .right
        } else {
            copyButton.contentHorizontalAlignment = .left
        }
        copyButton.addTarget(self, action: #selector(didPressCopy), for: .touchUpInside)
        addSubview(copyButton)
    }

    private func makeSearchSuggestionButton(atIndex i: Int) {
        let searchButton = IndexedInsetButton()
        searchButton.isHidden = true
        searchButton.accessibilityIdentifier = "OverlayView.searchButton"
        searchButton.setImage(#imageLiteral(resourceName: "icon_searchfor"), for: .normal)
        searchButton.setImage(#imageLiteral(resourceName: "icon_searchfor"), for: .highlighted)
        searchButton.backgroundColor = UIConstants.colors.background
        searchButton.titleLabel?.font = UIConstants.fonts.searchButton
        searchButton.backgroundColor = UIConstants.colors.background
        searchButton.setIndex(i)
        setUpOverlayButton(button: searchButton)
        searchButton.addTarget(self, action: #selector(didPressSearch(sender:)), for: .touchUpInside)
        self.searchButtonGroup.append(searchButton)
        addSubview(searchButton)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            button.titleEdgeInsets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding * 2)
        } else {
            button.titleEdgeInsets = UIEdgeInsets(top: padding, left: padding * 2, bottom: padding, right: padding)
        }
    }

    /**
     
     Localize and style 'phrase' text for use as a button title.
     
     - Parameter phrase: The phrase text for a button title
     - Parameter localizedStringFormat: The localization format string to apply
     
     - Returns: An NSAttributedString with `phrase` localized and styled appropriately.
     
     */
    func getAttributedButtonTitle(phrase: String,
                                  localizedStringFormat: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: localizedStringFormat, attributes: [.foregroundColor: UIConstants.Photon.Grey10])
        let phraseString = NSAttributedString(string: phrase, attributes: [.font: UIConstants.fonts.copyButtonQuery,
                                                                           .foregroundColor: UIConstants.Photon.Grey10])

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

    private func setURLicon(phrase: String, button: InsetButton) {
        if phrase.isUrl {
            button.setImage(#imageLiteral(resourceName: "icon_link"), for: .normal)
            button.setImage(#imageLiteral(resourceName: "icon_link"), for: .highlighted)
        } else {
            button.setImage(#imageLiteral(resourceName: "icon_searchfor"), for: .normal)
            button.setImage(#imageLiteral(resourceName: "icon_searchfor"), for: .highlighted)
        }
    }

    func setSearchQuery(suggestions: [String], hideFindInPage: Bool) {
        searchQuery = suggestions[0]
        searchSuggestions = searchQuery.isEmpty ? [] : suggestions
        let searchSuggestionsPromptHidden = UserDefaults.standard.bool(forKey: SearchSuggestionsPromptView.respondedToSearchSuggestionsPrompt) || searchQuery.isEmpty
        var copyButtonHidden = true

        UIPasteboard.general.urlAsync() { handoffUrl in
            DispatchQueue.main.async {
                if let url = handoffUrl, url.isWebPage() {
                    let attributedTitle = NSMutableAttributedString(string: UIConstants.strings.copiedLink, attributes: [.foregroundColor: UIConstants.Photon.Grey10])
                    let attributedCopiedUrl = NSMutableAttributedString(string: url.absoluteString, attributes: [.font: UIConstants.fonts.copyButtonQuery, .foregroundColor: UIConstants.Photon.Grey10])
                    attributedTitle.append(attributedCopiedUrl)
                    self.copyButton.setAttributedTitle(attributedTitle, for: .normal)
                    copyButtonHidden = !url.isWebPage()
                }

                self.updateSearchSuggestionsPrompt(hidden: searchSuggestionsPromptHidden)

                // Hide the autocomplete button on home screen and when the user is typing
                self.addToAutocompleteButton.animateHidden(self.searchButton.isHidden == self.searchQuery.isEmpty, duration: 0)
                self.topBorder.backgroundColor =  searchSuggestionsPromptHidden ? UIConstants.Photon.Grey90.withAlphaComponent(0.4) : UIColor(rgb: 0x42455A)
                self.updateSearchButtons()

                let lastSearchButtonIndex = min(self.searchSuggestions.count, self.searchButtonGroup.count) - 1
                self.updateFindInPageConstraints(
                    findInPageHidden: hideFindInPage,
                    lastSearchButtonIndex: lastSearchButtonIndex
                )
                self.updateCopyConstraints(
                    copyButtonHidden: copyButtonHidden,
                    findInPageHidden: hideFindInPage,
                    lastSearchButtonIndex: lastSearchButtonIndex
                )
            }
        }
    }

    fileprivate func updateSearchButtons() {
        for index in 0..<self.searchButtonGroup.count {
            let hasSuggestionInIndex = index < self.searchSuggestions.count
            self.searchButtonGroup[index].isHidden = !hasSuggestionInIndex

            if hasSuggestionInIndex {
                self.setAttributedButtonTitle(
                    phrase: self.searchSuggestions[index],
                    button: self.searchButtonGroup[index],
                    localizedStringFormat: Settings.getToggle(.enableSearchSuggestions) ? "" : UIConstants.strings.searchButton
                )
                self.setURLicon(phrase: self.searchSuggestions[index], button: self.searchButtonGroup[index])
            }
        }
    }

    fileprivate func updateFindInPageConstraints(findInPageHidden: Bool, lastSearchButtonIndex: Int) {
        findInPageButton.isHidden = findInPageHidden

        findInPageButton.snp.remakeConstraints { (make) in
            make.leading.trailing.equalTo(safeAreaLayoutGuide)
            if lastSearchButtonIndex >= 0 && !searchButtonGroup[lastSearchButtonIndex].isHidden {
                make.top.equalTo(searchButtonGroup[lastSearchButtonIndex].snp.bottom)
            } else {
                make.top.equalTo(topBorder.snp.bottom)
            }
            make.height.equalTo(UIConstants.layout.overlayButtonHeight)
        }

        self.setAttributedButtonTitle(phrase: self.searchQuery, button: self.findInPageButton, localizedStringFormat: UIConstants.strings.findInPageButton)
    }

    fileprivate func updateCopyConstraints(copyButtonHidden: Bool, findInPageHidden: Bool, lastSearchButtonIndex: Int) {
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

    @objc private func didPressSearch(sender: IndexedInsetButton) {
        delegate?.overlayView(self, didSearchForQuery: searchSuggestions[sender.getIndex()])

        if !Settings.getToggle(.enableSearchSuggestions) { return }
        if sender.getIndex() == 0 {
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.searchSuggestionNotSelected)
        } else {
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.searchSuggestionSelected)
        }
    }
    @objc private func didPressCopy() {
        delegate?.overlayView(self, didSubmitText: UIPasteboard.general.string!)
    }
    @objc private func didPressFindOnPage() {
        delegate?.overlayView(self, didSearchOnPage: searchQuery)
    }
    @objc private func didPressAddToAutocomplete() {
        delegate?.overlayView(self, didAddToAutocomplete: currentURL)
    }
    @objc private func didPressSettings() {
        delegate?.overlayViewDidPressSettings(self)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        delegate?.overlayViewDidTouchEmptyArea(self)
    }

    func dismiss() {
        setSearchQuery(suggestions: [""], hideFindInPage: true)
        self.isUserInteractionEnabled = false
        animateHidden(true, duration: UIConstants.layout.overlayAnimationDuration) {
            self.isUserInteractionEnabled = true
        }
    }

    func present() {
        setSearchQuery(suggestions: [""], hideFindInPage: true)
        self.isUserInteractionEnabled = false
        copyButton.isHidden = false
        addToAutocompleteButton.animateHidden(currentURL.isEmpty, duration: 0)
        animateHidden(false, duration: UIConstants.layout.overlayAnimationDuration) {
            self.isUserInteractionEnabled = true
        }
    }

    func setSearchSuggestionsPromptViewDelegate(delegate: SearchSuggestionsPromptViewDelegate) {
        searchSuggestionsPrompt.delegate = delegate
    }

    func updateSearchSuggestionsPrompt(hidden: Bool) {
        searchSuggestionsPrompt.isHidden = hidden

        searchSuggestionsPrompt.snp.remakeConstraints { make in
            make.top.leading.trailing.equalTo(safeAreaLayoutGuide)

            if hidden {
                make.height.equalTo(0)
            }
        }
    }
}
extension URL {
    public func isWebPage() -> Bool {
        let schemes = ["http", "https"]
        if let scheme = scheme, schemes.contains(scheme) {
            return true
        }
        return false
    }
}

extension OverlayView: KeyboardHelperDelegate {
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {}
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {}
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {}
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidHideWithState state: KeyboardState) {}
}

extension UIPasteboard {

    //
    // As of iOS 11: macOS/iOS's Universal Clipboard feature causes UIPasteboard to block.
    //
    // (Known) Apple Radars that have been filed:
    //
    //  http://www.openradar.me/28787338
    //  http://www.openradar.me/28774309
    //
    // Discussion on Twitter:
    //
    //  https://twitter.com/steipete/status/787985965432369152
    //
    //  To workaround this, urlAsync(callback:) makes a call of UIPasteboard.general on
    //  an async dispatch queue, calling the completion block when done.
    //
    func urlAsync(callback: @escaping (URL?) -> Void) {
        DispatchQueue.global().async {
            let url = URL(string: UIPasteboard.general.string ?? "")
            callback(url)
        }
    }
}
