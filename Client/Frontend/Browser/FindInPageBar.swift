/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

protocol FindInPageBarDelegate: class {
    func findInPage(findInPage: FindInPageBar, didTextChange text: String)
    func findInPage(findInPage: FindInPageBar, didFindPreviousWithText text: String)
    func findInPage(findInPage: FindInPageBar, didFindNextWithText text: String)
    func findInPageDidPressClose(findInPage: FindInPageBar)
}

private struct FindInPageUX {
    static let ButtonColor = UIColor.blackColor()
    static let MatchCountColor = UIColor.lightGrayColor()
    static let MatchCountFont = UIConstants.DefaultChromeFont
    static let SearchTextColor = UIColor(rgb: 0xe66000)
    static let SearchTextFont = UIConstants.DefaultChromeFont
    static let TopBorderColor = UIColor(rgb: 0xEEEEEE)
}

class FindInPageBar: UIView {
    weak var delegate: FindInPageBarDelegate?
    private let searchText = UITextField()
    private let matchCountView = UILabel()
    private let previousButton = UIButton()
    private let nextButton = UIButton()

    var currentResult = 0 {
        didSet {
            matchCountView.text = "\(currentResult)/\(totalResults)"
        }
    }

    var totalResults = 0 {
        didSet {
            matchCountView.text = "\(currentResult)/\(totalResults)"
            previousButton.enabled = totalResults > 1
            nextButton.enabled = previousButton.enabled
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

        backgroundColor = UIColor.whiteColor()

        searchText.addTarget(self, action: #selector(FindInPageBar.SELdidTextChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        searchText.textColor = FindInPageUX.SearchTextColor
        searchText.font = FindInPageUX.SearchTextFont
        searchText.autocapitalizationType = UITextAutocapitalizationType.None
        searchText.autocorrectionType = UITextAutocorrectionType.No
        if #available(iOS 9.0, *) {
            searchText.inputAssistantItem.leadingBarButtonGroups = []
            searchText.inputAssistantItem.trailingBarButtonGroups = []
        }
        searchText.enablesReturnKeyAutomatically = true
        searchText.returnKeyType = .Search
        addSubview(searchText)

        matchCountView.textColor = FindInPageUX.MatchCountColor
        matchCountView.font = FindInPageUX.MatchCountFont
        matchCountView.hidden = true
        addSubview(matchCountView)

        previousButton.setImage(UIImage(named: "find_previous"), forState: UIControlState.Normal)
        previousButton.setTitleColor(FindInPageUX.ButtonColor, forState: UIControlState.Normal)
        previousButton.accessibilityLabel = NSLocalizedString("Previous in-page result", tableName: "FindInPage", comment: "Accessibility label for previous result button in Find in Page Toolbar.")
        previousButton.addTarget(self, action: #selector(FindInPageBar.SELdidFindPrevious(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        addSubview(previousButton)

        nextButton.setImage(UIImage(named: "find_next"), forState: UIControlState.Normal)
        nextButton.setTitleColor(FindInPageUX.ButtonColor, forState: UIControlState.Normal)
        nextButton.accessibilityLabel = NSLocalizedString("Next in-page result", tableName: "FindInPage", comment: "Accessibility label for next result button in Find in Page Toolbar.")
        nextButton.addTarget(self, action: #selector(FindInPageBar.SELdidFindNext(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        addSubview(nextButton)

        let closeButton = UIButton()
        closeButton.setImage(UIImage(named: "find_close"), forState: UIControlState.Normal)
        closeButton.setTitleColor(FindInPageUX.ButtonColor, forState: UIControlState.Normal)
        closeButton.accessibilityLabel = NSLocalizedString("Done", tableName: "FindInPage", comment: "Done button in Find in Page Toolbar.")
        closeButton.addTarget(self, action: #selector(FindInPageBar.SELdidPressClose(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        addSubview(closeButton)

        let topBorder = UIView()
        topBorder.backgroundColor = FindInPageUX.TopBorderColor
        addSubview(topBorder)

        searchText.snp_makeConstraints { make in
            make.leading.top.bottom.equalTo(self).inset(UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0))
        }

        matchCountView.snp_makeConstraints { make in
            make.leading.equalTo(searchText.snp_trailing)
            make.centerY.equalTo(self)
        }

        previousButton.snp_makeConstraints { make in
            make.leading.equalTo(matchCountView.snp_trailing)
            make.size.equalTo(self.snp_height)
            make.centerY.equalTo(self)
        }

        nextButton.snp_makeConstraints { make in
            make.leading.equalTo(previousButton.snp_trailing)
            make.size.equalTo(self.snp_height)
            make.centerY.equalTo(self)
        }

        closeButton.snp_makeConstraints { make in
            make.leading.equalTo(nextButton.snp_trailing)
            make.size.equalTo(self.snp_height)
            make.trailing.centerY.equalTo(self)
        }

        topBorder.snp_makeConstraints { make in
            make.height.equalTo(1)
            make.left.right.top.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        searchText.becomeFirstResponder()
        return super.becomeFirstResponder()
    }

    @objc private func SELdidFindPrevious(sender: UIButton) {
        delegate?.findInPage(self, didFindPreviousWithText: searchText.text ?? "")
    }

    @objc private func SELdidFindNext(sender: UIButton) {
        delegate?.findInPage(self, didFindNextWithText: searchText.text ?? "")
    }

    @objc private func SELdidTextChange(sender: UITextField) {
        matchCountView.hidden = searchText.text?.isEmpty ?? true
        delegate?.findInPage(self, didTextChange: searchText.text ?? "")
    }

    @objc private func SELdidPressClose(sender: UIButton) {
        delegate?.findInPageDidPressClose(self)
    }
}
