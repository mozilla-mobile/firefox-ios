/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

protocol FindInPageBarDelegate: class {
    func findInPage(findInPage: FindInPageBar, didTextChange text: String)
    func findInPage(findInPage: FindInPageBar, didFindPreviousWithText text: String)
    func findInPage(findInPage: FindInPageBar, didFindNextWithText text: String)
    func findInPageDidPressDone(findInPage: FindInPageBar)
}

class FindInPageBar: UIView {
    weak var delegate: FindInPageBarDelegate?
    private let searchText = UITextField()
    private let matchCountView = UILabel()

    var currentResult = 0 {
        didSet {
            matchCountView.text = "\(currentResult)/\(totalResults)"
        }
    }

    var totalResults = 0 {
        didSet {
            matchCountView.text = "\(currentResult)/\(totalResults)"
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.whiteColor()
        layer.borderColor = UIConstants.BorderColor.CGColor
        layer.borderWidth = 1

        searchText.addTarget(self, action: "didTextChange:", forControlEvents: UIControlEvents.EditingChanged)
        addSubview(searchText)

        matchCountView.textColor = UIColor.lightGrayColor()
        matchCountView.text = "0/0"
        matchCountView.font = UIConstants.DefaultMediumFont
        addSubview(matchCountView)

        let previousButton = UIButton()
        previousButton.setTitle("<", forState: UIControlState.Normal)
        previousButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        addSubview(previousButton)
        previousButton.addTarget(self, action: "didFindPrevious:", forControlEvents: UIControlEvents.TouchUpInside)

        let nextButton = UIButton()
        nextButton.setTitle(">", forState: UIControlState.Normal)
        nextButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        nextButton.addTarget(self, action: "didFindNext:", forControlEvents: UIControlEvents.TouchUpInside)
        addSubview(nextButton)

        let doneButton = UIButton()
        doneButton.setTitle("x", forState: UIControlState.Normal)
        doneButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        doneButton.addTarget(self, action: "didPressDone:", forControlEvents: UIControlEvents.TouchUpInside)
        addSubview(doneButton)

        searchText.snp_makeConstraints { make in
            make.leading.equalTo(self).offset(8)
            make.top.bottom.equalTo(self)
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

        doneButton.snp_makeConstraints { make in
            make.leading.equalTo(nextButton.snp_trailing)
            make.size.equalTo(self.snp_height)
            make.centerY.equalTo(self)
            make.trailing.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        return searchText.becomeFirstResponder()
    }

    @objc func didFindPrevious(sender: UIButton) {
        delegate?.findInPage(self, didFindPreviousWithText: searchText.text ?? "")
    }

    @objc func didFindNext(sender: UIButton) {
        delegate?.findInPage(self, didFindNextWithText: searchText.text ?? "")
    }

    @objc func didTextChange(sender: UITextField) {
        delegate?.findInPage(self, didTextChange: searchText.text ?? "")
    }

    @objc func didPressDone(sender: UIButton) {
        searchText.text = ""
        delegate?.findInPageDidPressDone(self)
    }
}