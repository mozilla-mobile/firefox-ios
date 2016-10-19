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

    fileprivate let settingsButton = InsetButton()

    private let searchButton = InsetButton()
    private let searchBorder = UIView()
    private var bottomConstraint: Constraint!

    init() {
        super.init(frame: CGRect.zero)

        KeyboardHelper.defaultHelper.addDelegate(delegate: self)

        searchButton.isHidden = true
        searchButton.alpha = 0
        searchButton.titleLabel?.font = UIConstants.fonts.searchButton
        searchButton.titleLabel?.lineBreakMode = .byTruncatingTail
        searchButton.contentHorizontalAlignment = .left
        searchButton.setImage(#imageLiteral(resourceName: "icon_searchfor"), for: .normal)
        let padding = UIConstants.layout.searchButtonInset
        searchButton.imageEdgeInsets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        searchButton.titleEdgeInsets = UIEdgeInsets(top: padding, left: padding * 2, bottom: padding, right: padding)
        searchButton.addTarget(self, action: #selector(didPressSearch), for: .touchUpInside)
        addSubview(searchButton)

        searchBorder.isHidden = true
        searchBorder.alpha = 0
        searchBorder.backgroundColor = UIConstants.colors.settingsButtonBorder
        addSubview(searchBorder)

        let settingsBackground = GradientBackgroundView()
        addSubview(settingsBackground)

        settingsButton.setTitle(UIConstants.strings.openSettings, for: .normal)
        settingsButton.titleLabel?.font = UIConstants.fonts.settingsButton
        settingsButton.titleEdgeInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        settingsButton.addTarget(self, action: #selector(didPressSettings), for: .touchUpInside)
        addSubview(settingsButton)

        let settingsBorder = UIView()
        settingsBorder.backgroundColor = UIConstants.colors.settingsButtonBorder
        addSubview(settingsBorder)

        searchButton.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(self)
        }

        searchBorder.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(searchButton.snp.bottom)
            make.height.equalTo(1)
        }

        settingsBackground.snp.makeConstraints { make in
            make.edges.equalTo(settingsButton)
        }

        settingsButton.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            bottomConstraint = make.bottom.equalTo(self).constraint
        }

        settingsBorder.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.bottom.equalTo(settingsButton.snp.top)
            make.height.equalTo(1)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var searchQuery: String = "" {
        didSet {
            if searchButton.isHidden != searchQuery.isEmpty {
                searchButton.animateHidden(searchQuery.isEmpty, duration: UIConstants.layout.searchButtonAnimationDuration)
                searchBorder.animateHidden(searchQuery.isEmpty, duration: UIConstants.layout.searchButtonAnimationDuration)
            }

            // Use [ and ] to help find the position of the search query, then delete them.
            let searchTitle = NSMutableString(string: String(format: UIConstants.strings.searchButton, "[\(searchQuery)]"))
            let startIndex = searchTitle.range(of: "[")
            let endIndex = searchTitle.range(of: "]", options: .backwards)
            searchTitle.deleteCharacters(in: endIndex)
            searchTitle.deleteCharacters(in: startIndex)

            let attributedString = NSMutableAttributedString(string: searchTitle as String)
            let queryRange = NSMakeRange(startIndex.location, searchQuery.characters.count)
            let fullRange = NSMakeRange(0, searchTitle.length)
            attributedString.addAttributes([NSFontAttributeName: UIConstants.fonts.searchButtonQuery], range: queryRange)
            attributedString.addAttributes([NSForegroundColorAttributeName: UIColor.white], range: fullRange)

            searchButton.setAttributedTitle(attributedString, for: .normal)
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

    @objc private func didPressSettings() {
        delegate?.overlayViewDidPressSettings(self)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        delegate?.overlayViewDidTouchEmptyArea(self)
    }
}

extension OverlayView: KeyboardHelperDelegate {
    public func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        animateWithKeyboard(keyboardState: state)
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {

    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        animateWithKeyboard(keyboardState: state)
    }
}
