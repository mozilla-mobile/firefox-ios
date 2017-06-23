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
}

class OverlayView: UIView {
    weak var delegate: OverlayViewDelegate?
    fileprivate let settingsButton = UIButton()
    private let searchButton = InsetButton()
    private let searchBorder = UIView()
    private var bottomConstraint: Constraint!
    private var presented = false
    private var searchQuery = ""
    private let copyButton = InsetButton()
    private let copyBorder = UIView()

    init() {
        super.init(frame: CGRect.zero)
        KeyboardHelper.defaultHelper.addDelegate(delegate: self)
        searchButton.isHidden = true
        searchButton.alpha = 0
        searchButton.setImage(#imageLiteral(resourceName: "icon_searchfor"), for: .normal)
        searchButton.setImage(#imageLiteral(resourceName: "icon_searchfor"), for: .highlighted)
        searchButton.titleLabel?.font = UIConstants.fonts.searchButton
        setUpOverlayButton(button: searchButton)
        searchButton.addTarget(self, action: #selector(didPressSearch), for: .touchUpInside)
        addSubview(searchButton)

        searchBorder.isHidden = true
        searchBorder.alpha = 0
        searchBorder.backgroundColor = UIConstants.colors.settingsButtonBorder
        addSubview(searchBorder)
        searchButton.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(self)
        }
        searchBorder.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(searchButton.snp.bottom)
            make.height.equalTo(1)
        }
        
        copyButton.setImage(#imageLiteral(resourceName: "icon_paste"), for: .normal)
        copyButton.setImage(#imageLiteral(resourceName: "icon_paste"), for: .highlighted)
        copyButton.titleLabel?.font = UIConstants.fonts.copyButton
        setUpOverlayButton(button: copyButton)
        copyButton.addTarget(self, action: #selector(didPressCopy), for: .touchUpInside)
        addSubview(copyButton)
        
        copyBorder.backgroundColor = UIConstants.colors.copyButtonBorder
        addSubview(copyBorder)
        
        copyButton.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(self)
        }
        copyBorder.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(copyButton.snp.bottom)
            make.height.equalTo(1)
        }
        
        settingsButton.setImage(#imageLiteral(resourceName: "icon_settings"), for: .normal)
        settingsButton.contentEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        settingsButton.addTarget(self, action: #selector(didPressSettings), for: .touchUpInside)
        settingsButton.accessibilityLabel = UIConstants.strings.browserSettings
        addSubview(settingsButton)
        
        settingsButton.snp.makeConstraints { make in
            make.trailing.equalTo(self)
            bottomConstraint = make.bottom.equalTo(self).constraint
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
    func setAttributedButtonTitle(phrase: String, button: InsetButton) {
        // Use [ and ] to help find the position of the query, then delete them.
        let copyTitle = NSMutableString(string: String(format: UIConstants.strings.searchButton, "[\(phrase)]"))
        let startIndex = copyTitle.range(of: "[")
        let endIndex = copyTitle.range(of: "]")
        copyTitle.deleteCharacters(in: endIndex)
        copyTitle.deleteCharacters(in: startIndex)
        
        let attributedString = NSMutableAttributedString(string: copyTitle as String)
        let queryRange = NSMakeRange(startIndex.location, (phrase as NSString).length)
        let fullRange = NSMakeRange(0, copyTitle.length)
        attributedString.addAttributes([NSFontAttributeName: UIConstants.fonts.copyButtonQuery], range: queryRange)
        attributedString.addAttributes([NSForegroundColorAttributeName: UIColor.white], range: fullRange)
        
        button.setAttributedTitle(attributedString, for: .normal)
    }
    func setSearchQuery(query: String, animated: Bool) {
        searchQuery = query
        let query = query.trimmingCharacters(in: .whitespaces)
        
        if let pasteBoard = UIPasteboard.general.string {
            if let pasteURL = URL(string: pasteBoard), pasteURL.isWebPage() {
                let attributedURL = NSAttributedString(string: pasteURL.absoluteString, attributes: [NSForegroundColorAttributeName: UIColor.white])
                    copyButton.setAttributedTitle(attributedURL, for: .normal)
            }
            else {
                setAttributedButtonTitle(phrase: pasteBoard, button: copyButton)
            }
        }
        // Show or hide the search button depending on whether there's entered text.
        if searchButton.isHidden != query.isEmpty {
            let duration = animated ? UIConstants.layout.searchButtonAnimationDuration : 0
            searchButton.animateHidden(query.isEmpty, duration: duration)
            searchBorder.animateHidden(query.isEmpty, duration: duration)
            updateCopyConstraint()
        }
        setAttributedButtonTitle(phrase: query, button: searchButton)
        updateCopyConstraint()
    }
    fileprivate func updateCopyConstraint() {
        if UIPasteboard.general.string != nil {
            copyButton.isHidden = false
            copyBorder.isHidden = false
            if searchButton.isHidden || searchQuery.isEmpty {
                copyButton.snp.remakeConstraints { make in
                    make.top.leading.trailing.equalTo(self)
                }
            } else {
                copyButton.snp.remakeConstraints { make in
                    make.leading.trailing.equalTo(self)
                    make.top.equalTo(searchBorder)
                }
            }
        } else {
            copyButton.isHidden = true
            copyBorder.isHidden = true
        }
    }

    fileprivate func animateWithKeyboard(keyboardState: KeyboardState) {
        UIView.animate(withDuration: keyboardState.animationDuration, animations: {
            let keyboardHeight = keyboardState.intersectionHeightForView(view: self)
            self.bottomConstraint.update(offset: -keyboardHeight)
            self.layoutIfNeeded()
        })
    }

    @objc private func didPressSearch() {
        delegate?.overlayView(self, didSearchForQuery: searchQuery)
    }
    @objc private func didPressCopy() {
        delegate?.overlayView(self, didSubmitText: UIPasteboard.general.string!)
    }
    @objc private func didPressSettings() {
        delegate?.overlayViewDidPressSettings(self)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        delegate?.overlayViewDidTouchEmptyArea(self)
    }

    func dismiss() {
        setSearchQuery(query: "", animated: false)
        self.isUserInteractionEnabled = false
        animateHidden(true, duration: UIConstants.layout.overlayAnimationDuration) {
            self.isUserInteractionEnabled = true
        }
    }

    func present() {
        setSearchQuery(query: "", animated: false)
        self.isUserInteractionEnabled = false
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
    public func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        animateWithKeyboard(keyboardState: state)
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        animateWithKeyboard(keyboardState: state)
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {}
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidHideWithState state: KeyboardState) {}
}
