/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

protocol FindInPageBarDelegate: class {
    func findInPage(_ findInPage: FindInPageBar, didTextChange text: String)
    func findInPage(_ findInPage: FindInPageBar, didFindPreviousWithText text: String)
    func findInPage(_ findInPage: FindInPageBar, didFindNextWithText text: String)
    func findInPageDidPressClose(_ findInPage: FindInPageBar)
}

private struct FindInPageUX {
    static let ButtonColor = UIColor.black
    static let MatchCountColor = UIColor.lightGray
    static let MatchCountFont = UIConstants.DefaultChromeFont
    static let SearchTextColor = UIColor(rgb: 0xe66000)
    static let SearchTextFont = UIConstants.DefaultChromeFont
    static let TopBorderColor = UIColor(rgb: 0xEEEEEE)
}

class FindInPageBar: UIView {
    weak var delegate: FindInPageBarDelegate?
    fileprivate let searchText = UITextField()
    fileprivate let matchCountView = UILabel()
    fileprivate let previousButton = UIButton()
    fileprivate let nextButton = UIButton()

    var currentResult = 0 {
        didSet {
            matchCountView.text = "\(currentResult)/\(totalResults)"
        }
    }

    var totalResults = 0 {
        didSet {
            matchCountView.text = "\(currentResult)/\(totalResults)"
            previousButton.isEnabled = totalResults > 1
            nextButton.isEnabled = previousButton.isEnabled
        }
    }

    var text: String? {
        get {
            return searchText.text
        }

        set {
            searchText.text = newValue
            SELdidTextChange(searchText)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.white

        searchText.addTarget(self, action: #selector(FindInPageBar.SELdidTextChange(_:)), for: UIControlEvents.editingChanged)
        searchText.textColor = FindInPageUX.SearchTextColor
        searchText.font = FindInPageUX.SearchTextFont
        searchText.autocapitalizationType = UITextAutocapitalizationType.none
        searchText.autocorrectionType = UITextAutocorrectionType.no
        searchText.inputAssistantItem.leadingBarButtonGroups = []
        searchText.inputAssistantItem.trailingBarButtonGroups = []
        searchText.enablesReturnKeyAutomatically = true
        searchText.returnKeyType = .search
        addSubview(searchText)

        matchCountView.textColor = FindInPageUX.MatchCountColor
        matchCountView.font = FindInPageUX.MatchCountFont
        matchCountView.isHidden = true
        addSubview(matchCountView)

        previousButton.setImage(UIImage(named: "find_previous"), for: UIControlState())
        previousButton.setTitleColor(FindInPageUX.ButtonColor, for: UIControlState())
        previousButton.accessibilityLabel = NSLocalizedString("Previous in-page result", tableName: "FindInPage", comment: "Accessibility label for previous result button in Find in Page Toolbar.")
        previousButton.addTarget(self, action: #selector(FindInPageBar.SELdidFindPrevious(_:)), for: UIControlEvents.touchUpInside)
        addSubview(previousButton)

        nextButton.setImage(UIImage(named: "find_next"), for: UIControlState())
        nextButton.setTitleColor(FindInPageUX.ButtonColor, for: UIControlState())
        nextButton.accessibilityLabel = NSLocalizedString("Next in-page result", tableName: "FindInPage", comment: "Accessibility label for next result button in Find in Page Toolbar.")
        nextButton.addTarget(self, action: #selector(FindInPageBar.SELdidFindNext(_:)), for: UIControlEvents.touchUpInside)
        addSubview(nextButton)

        let closeButton = UIButton()
        closeButton.setImage(UIImage(named: "find_close"), for: UIControlState())
        closeButton.setTitleColor(FindInPageUX.ButtonColor, for: UIControlState())
        closeButton.accessibilityLabel = NSLocalizedString("Done", tableName: "FindInPage", comment: "Done button in Find in Page Toolbar.")
        closeButton.addTarget(self, action: #selector(FindInPageBar.SELdidPressClose(_:)), for: UIControlEvents.touchUpInside)
        addSubview(closeButton)

        let topBorder = UIView()
        topBorder.backgroundColor = FindInPageUX.TopBorderColor
        addSubview(topBorder)

        searchText.snp.makeConstraints { make in
            make.leading.top.bottom.equalTo(self).inset(UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0))
        }

        matchCountView.snp.makeConstraints { make in
            make.leading.equalTo(searchText.snp.trailing)
            make.centerY.equalTo(self)
        }

        previousButton.snp.makeConstraints { make in
            make.leading.equalTo(matchCountView.snp.trailing)
            make.size.equalTo(self.snp.height)
            make.centerY.equalTo(self)
        }

        nextButton.snp.makeConstraints { make in
            make.leading.equalTo(previousButton.snp.trailing)
            make.size.equalTo(self.snp.height)
            make.centerY.equalTo(self)
        }

        closeButton.snp.makeConstraints { make in
            make.leading.equalTo(nextButton.snp.trailing)
            make.size.equalTo(self.snp.height)
            make.trailing.centerY.equalTo(self)
        }

        topBorder.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.left.right.top.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @discardableResult override func becomeFirstResponder() -> Bool {
        searchText.becomeFirstResponder()
        return super.becomeFirstResponder()
    }

    @objc fileprivate func SELdidFindPrevious(_ sender: UIButton) {
        delegate?.findInPage(self, didFindPreviousWithText: searchText.text ?? "")
    }

    @objc fileprivate func SELdidFindNext(_ sender: UIButton) {
        delegate?.findInPage(self, didFindNextWithText: searchText.text ?? "")
    }

    @objc fileprivate func SELdidTextChange(_ sender: UITextField) {
        matchCountView.isHidden = searchText.text?.isEmpty ?? true
        delegate?.findInPage(self, didTextChange: searchText.text ?? "")
    }

    @objc fileprivate func SELdidPressClose(_ sender: UIButton) {
        delegate?.findInPageDidPressClose(self)
    }
}
