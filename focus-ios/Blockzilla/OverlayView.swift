/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit

protocol OverlayViewDelegate: class {
    func overlayViewDidTouchEmptyArea(_ overlayView: OverlayView)
    func overlayViewDidPressSettings(_ overlayView: OverlayView)
    func overlayView(_ overlayView: OverlayView, didSearchForQuery query: String)
}

class OverlayView: UIView {
    weak var delegate: OverlayViewDelegate?

    fileprivate let settingsButton = UIButton()

    private let searchButton = InsetButton()
    private let searchBorder = UIView()
    private var bottomConstraint: Constraint!
    private var presented = false
    private var searchQuery = ""

    init() {
        super.init(frame: CGRect.zero)

        KeyboardHelper.defaultHelper.addDelegate(delegate: self)

        searchButton.isHidden = true
        searchButton.alpha = 0
        searchButton.titleLabel?.font = UIConstants.fonts.searchButton
        searchButton.titleLabel?.lineBreakMode = .byTruncatingTail
        searchButton.contentHorizontalAlignment = .left
        searchButton.setImage(#imageLiteral(resourceName: "icon_searchfor"), for: .normal)
        searchButton.setImage(#imageLiteral(resourceName: "icon_searchfor"), for: .highlighted)

        let padding = UIConstants.layout.searchButtonInset
        searchButton.imageEdgeInsets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        searchButton.titleEdgeInsets = UIEdgeInsets(top: padding, left: padding * 2, bottom: padding, right: padding)
        searchButton.addTarget(self, action: #selector(didPressSearch), for: .touchUpInside)
        addSubview(searchButton)

        searchBorder.isHidden = true
        searchBorder.alpha = 0
        searchBorder.backgroundColor = UIConstants.colors.settingsButtonBorder
        addSubview(searchBorder)

        settingsButton.setImage(#imageLiteral(resourceName: "icon_settings"), for: .normal)
        settingsButton.contentEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        settingsButton.addTarget(self, action: #selector(didPressSettings), for: .touchUpInside)
        settingsButton.accessibilityLabel = UIConstants.strings.browserSettings
        addSubview(settingsButton)

        searchButton.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(self)
        }

        searchBorder.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(searchButton.snp.bottom)
            make.height.equalTo(1)
        }

        settingsButton.snp.makeConstraints { make in
            make.trailing.equalTo(self)
            bottomConstraint = make.bottom.equalTo(self).constraint
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSearchQuery(query: String, animated: Bool) {
        searchQuery = query

        let query = query.trimmingCharacters(in: .whitespaces)

        // Show or hide the search button depending on whether there's entered text.
        if searchButton.isHidden != query.isEmpty {
            let duration = animated ? UIConstants.layout.searchButtonAnimationDuration : 0
            searchButton.animateHidden(query.isEmpty, duration: duration)
            searchBorder.animateHidden(query.isEmpty, duration: duration)
        }

        // Use [ and ] to help find the position of the search query, then delete them.
        let searchTitle = NSMutableString(string: String(format: UIConstants.strings.searchButton, "[\(query)]"))
        let startIndex = searchTitle.range(of: "[")
        let endIndex = searchTitle.range(of: "]", options: .backwards)
        searchTitle.deleteCharacters(in: endIndex)
        searchTitle.deleteCharacters(in: startIndex)

        let attributedString = NSMutableAttributedString(string: searchTitle as String)
        let queryRange = NSMakeRange(startIndex.location, (query as NSString).length)
        let fullRange = NSMakeRange(0, searchTitle.length)
        attributedString.addAttributes([NSFontAttributeName: UIConstants.fonts.searchButtonQuery], range: queryRange)
        attributedString.addAttributes([NSForegroundColorAttributeName: UIColor.white], range: fullRange)

        searchButton.setAttributedTitle(attributedString, for: .normal)
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
