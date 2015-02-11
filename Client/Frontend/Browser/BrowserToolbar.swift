/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Snappy

protocol BrowserToolbarDelegate {
    func didClickBack()
    func didClickForward()
    func didLongPressBack()
    func didLongPressForward()

    func didClickBookmark()
}

class BrowserToolbar: UIView {
    var browserToolbarDelegate: BrowserToolbarDelegate?

    private let shareButton: UIButton
    private let bookmarkButton: UIButton
    private let forwardButton: UIButton
    private let backButton: UIButton
    private let longPressGestureBackButton: UILongPressGestureRecognizer!
    private let longPressGestureForwardButton: UILongPressGestureRecognizer!

    override init() {
        backButton = UIButton()
        forwardButton = UIButton()
        shareButton = UIButton()
        bookmarkButton = UIButton()

        super.init()

        backButton.setImage(UIImage(named: "back"), forState: .Normal)
        backButton.accessibilityLabel = NSLocalizedString("Back", comment: "")
        backButton.accessibilityHint = NSLocalizedString("Double tap and hold to open history", comment: "")
        longPressGestureBackButton = UILongPressGestureRecognizer(target: self, action: "SELdidLongPressBack:")
        backButton.addGestureRecognizer(longPressGestureBackButton)
        backButton.addTarget(self, action: "SELdidClickBack", forControlEvents: UIControlEvents.TouchUpInside)

        forwardButton.setImage(UIImage(named: "forward"), forState: .Normal)
        forwardButton.accessibilityLabel = NSLocalizedString("Forward", comment: "")
        forwardButton.accessibilityHint = NSLocalizedString("Double tap and hold to open history", comment: "")
        longPressGestureForwardButton = UILongPressGestureRecognizer(target: self, action: "SELdidLongPressForward:")
        forwardButton.addGestureRecognizer(longPressGestureForwardButton)
        forwardButton.addTarget(self, action: "SELdidClickForward", forControlEvents: UIControlEvents.TouchUpInside)

        shareButton.setImage(UIImage(named: "send"), forState: .Normal)
        shareButton.enabled = false

        bookmarkButton.setImage(UIImage(named: "bookmark"), forState: .Normal)
        bookmarkButton.addTarget(self, action: "SELdidClickBookmark", forControlEvents: UIControlEvents.TouchUpInside)

        addButtons(backButton, forwardButton, shareButton, bookmarkButton)
    }

    // This has to be here since init() calls it
    override private init(frame: CGRect) {
        // And these have to be initialized in here or the compiler will get angry
        backButton = UIButton()
        forwardButton = UIButton()
        shareButton = UIButton()
        bookmarkButton = UIButton()

        super.init(frame: frame)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addButtons(buttons: UIButton...) {
        for button in buttons {
            button.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
            button.setTitleColor(UIColor.grayColor(), forState: UIControlState.Disabled)
            button.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            addSubview(button)
        }
    }

    override func layoutSubviews() {
        var prev: UIView? = nil
        for view in self.subviews {
            if let view = view as? UIView {
                view.snp_remakeConstraints { make in
                    if let prev = prev {
                        make.left.equalTo(prev.snp_right)
                    } else {
                        make.left.equalTo(self)
                    }
                    prev = view

                    make.centerY.equalTo(self)
                    make.height.equalTo(ToolbarHeight - DefaultPadding * 2)
                    make.width.equalTo(self).dividedBy(self.subviews.count)
                }
            }
        }
    }

    func updateBackStatus(canGoBack: Bool) {
        backButton.enabled = canGoBack
    }

    func updateFowardStatus(canGoForward: Bool) {
        forwardButton.enabled = canGoForward
    }

    func updateBookmarkStatus(isBookmarked: Bool) {
        if isBookmarked {
            bookmarkButton.imageView?.image = UIImage(named: "bookmarked")
        } else {
            bookmarkButton.imageView?.image = UIImage(named: "bookmark")
        }
    }

    func SELdidClickBack() {
        browserToolbarDelegate?.didClickBack()
    }

    func SELdidLongPressBack(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Began {
            browserToolbarDelegate?.didLongPressBack()
        }
    }

    func SELdidClickForward() {
        browserToolbarDelegate?.didClickForward()
    }

    func SELdidLongPressForward(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Began {
            browserToolbarDelegate?.didLongPressForward()
        }
    }

    func SELdidClickBookmark() {
        browserToolbarDelegate?.didClickBookmark()
    }
}
