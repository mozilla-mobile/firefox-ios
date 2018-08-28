/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit

protocol OverlayViewDelegate: class {
    func overlayViewDidTouchEmptyArea(_ overlayView: OverlayView)
    func overlayViewDidPressSettings(_ overlayView: OverlayView)
    func overlayView(_ overlayView: OverlayView, didSearchForQuery query: String)
    func overlayView(_ overlayView: OverlayView, didSubmitText text: String)
    func overlayView(_ overlayView: OverlayView, didSearchOnPage query: String)
}

class OverlayView: UIView {
    weak var delegate: OverlayViewDelegate?
    private let searchButton = InsetButton()
    private var presented = false
    private var searchQuery = ""
    private let copyButton = UIButton()
    private let findInPageButton = InsetButton()
    private let topBorder = UIView()
    public var currentURL = ""

    init() {
        super.init(frame: CGRect.zero)
        KeyboardHelper.defaultHelper.addDelegate(delegate: self)
        
        searchButton.isHidden = true
        searchButton.accessibilityIdentifier = "OverlayView.searchButton"
        searchButton.alpha = 0
        searchButton.setImage(#imageLiteral(resourceName: "icon_searchfor"), for: .normal)
        searchButton.setImage(#imageLiteral(resourceName: "icon_searchfor"), for: .highlighted)
        searchButton.backgroundColor = UIConstants.colors.background
        searchButton.titleLabel?.font = UIConstants.fonts.searchButton
        searchButton.backgroundColor = UIConstants.colors.background
        setUpOverlayButton(button: searchButton)
        searchButton.addTarget(self, action: #selector(didPressSearch), for: .touchUpInside)
        addSubview(searchButton)
        
        topBorder.isHidden = true
        topBorder.alpha = 0
        topBorder.backgroundColor = UIConstants.Photon.Grey90.withAlphaComponent(0.4)
        addSubview(topBorder)
        
        topBorder.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(searchButton.snp.top)
            make.height.equalTo(1)
        }

        searchButton.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(safeAreaLayoutGuide)
        }
        
        let padding = UIConstants.layout.searchButtonInset
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
        
        findInPageButton.snp.makeConstraints { make in
            make.top.equalTo(searchButton.snp.bottom)
            make.leading.trailing.equalTo(safeAreaLayoutGuide)
            make.height.equalTo(56)
        }

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
        
        copyButton.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(safeAreaLayoutGuide)
            make.height.equalTo(56)
        }
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
    
    func setSearchQuery(query: String, animated: Bool, hideFindInPage: Bool) {
        searchQuery = query
        let query = query.trimmingCharacters(in: .whitespaces)

        var showCopyButton = false

        UIPasteboard.general.urlAsync() { handoffUrl in
            DispatchQueue.main.async {
                if let url = handoffUrl, url.isWebPage() {
                    let attributedTitle = NSMutableAttributedString(string: UIConstants.strings.copiedLink, attributes: [.foregroundColor : UIConstants.Photon.Grey10])
                    let attributedCopiedUrl = NSMutableAttributedString(string: url.absoluteString, attributes: [.font: UIConstants.fonts.copyButtonQuery, .foregroundColor : UIConstants.Photon.Grey10])
                    attributedTitle.append(attributedCopiedUrl)
                    self.copyButton.setAttributedTitle(attributedTitle, for: .normal)
                    showCopyButton = url.isWebPage()
                }
                
                // Show or hide the search button depending on whether there's entered text.
                if self.searchButton.isHidden != query.isEmpty {
                    let duration = animated ? UIConstants.layout.searchButtonAnimationDuration : 0
                    self.topBorder.animateHidden(query.isEmpty, duration: duration)
                    self.searchButton.animateHidden(query.isEmpty, duration: duration)
                    self.findInPageButton.animateHidden(query.isEmpty || hideFindInPage, duration: duration, completion: {
                        self.updateCopyConstraint(showCopyButton: showCopyButton)
                    })
                } else {
                    self.updateCopyConstraint(showCopyButton: showCopyButton)
                }

                self.setAttributedButtonTitle(phrase: query, button: self.searchButton, localizedStringFormat: UIConstants.strings.searchButton)
                self.setAttributedButtonTitle(phrase: query, button: self.findInPageButton, localizedStringFormat: UIConstants.strings.findInPageButton)
            }
        }
    }

    fileprivate func updateCopyConstraint(showCopyButton: Bool) {
        if showCopyButton {
            copyButton.isHidden = false
            if searchButton.isHidden || searchQuery.isEmpty {
                copyButton.snp.remakeConstraints { make in
                    make.top.leading.trailing.equalTo(safeAreaLayoutGuide)
                    make.height.equalTo(56)
                }
            } else if findInPageButton.isHidden {
                copyButton.snp.remakeConstraints { make in
                    make.leading.trailing.equalTo(safeAreaLayoutGuide)
                    make.top.equalTo(searchButton.snp.bottom)
                    make.height.equalTo(56)
                }
            } else {
                copyButton.snp.remakeConstraints { make in
                    make.leading.trailing.equalTo(safeAreaLayoutGuide)
                    make.top.equalTo(findInPageButton.snp.bottom)
                    make.height.equalTo(56)
                }
            }
        } else {
            copyButton.isHidden = true
        }
        layoutIfNeeded()
    }

    @objc private func didPressSearch() {
        delegate?.overlayView(self, didSearchForQuery: searchQuery)
    }
    @objc private func didPressCopy() {
        delegate?.overlayView(self, didSubmitText: UIPasteboard.general.string!)
    }
    @objc private func didPressFindOnPage() {
        delegate?.overlayView(self, didSearchOnPage: searchQuery)
    }
    @objc private func didPressSettings() {
        delegate?.overlayViewDidPressSettings(self)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        delegate?.overlayViewDidTouchEmptyArea(self)
    }

    func dismiss() {
        setSearchQuery(query: "", animated: false, hideFindInPage: true)
        self.isUserInteractionEnabled = false
        copyButton.isHidden = true
        animateHidden(true, duration: UIConstants.layout.overlayAnimationDuration) {
            self.isUserInteractionEnabled = true
        }
    }

    func present() {
        setSearchQuery(query: "", animated: false, hideFindInPage: true)
        self.isUserInteractionEnabled = false
        copyButton.isHidden = false
        animateHidden(false, duration: UIConstants.layout.overlayAnimationDuration) {
            self.isUserInteractionEnabled = true
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
