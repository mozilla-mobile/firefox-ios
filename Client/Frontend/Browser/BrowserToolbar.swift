/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Snap

protocol BrowserToolbarDelegate: class {
    func browserToolbarDidPressBack(browserToolbar: BrowserToolbar)
    func browserToolbarDidPressForward(browserToolbar: BrowserToolbar)
    func browserToolbarDidLongPressBack(browserToolbar: BrowserToolbar)
    func browserToolbarDidLongPressForward(browserToolbar: BrowserToolbar)
    func browserToolbarDidPressBookmark(browserToolbar: BrowserToolbar)
    func browserToolbarDidLongPressBookmark(browserToolbar: BrowserToolbar)
    func browserToolbarDidPressShare(browserToolbar: BrowserToolbar)
}

private let ButtonInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

class BrowserToolbar: Toolbar {
    weak var browserToolbarDelegate: BrowserToolbarDelegate?

    private let shareButton: UIButton
    private let bookmarkButton: UIButton
    private let forwardButton: UIButton
    private let backButton: UIButton
    private let longPressGestureBackButton: UILongPressGestureRecognizer!
    private let longPressGestureForwardButton: UILongPressGestureRecognizer!
    private let longPressGestureBookmarkButton: UILongPressGestureRecognizer!

    override init() {
        backButton = UIButton()
        forwardButton = UIButton()
        shareButton = UIButton()
        bookmarkButton = UIButton()

        super.init()

        backButton.setImage(UIImage(named: "back"), forState: .Normal)
        backButton.accessibilityLabel = NSLocalizedString("Back", comment: "Accessibility Label for the browser toolbar Back button")
        backButton.accessibilityHint = NSLocalizedString("Double tap and hold to open history", comment: "")
        longPressGestureBackButton = UILongPressGestureRecognizer(target: self, action: "SELdidLongPressBack:")
        backButton.addGestureRecognizer(longPressGestureBackButton)
        backButton.contentEdgeInsets = ButtonInset
        backButton.addTarget(self, action: "SELdidClickBack", forControlEvents: UIControlEvents.TouchUpInside)

        forwardButton.setImage(UIImage(named: "forward"), forState: .Normal)
        forwardButton.accessibilityLabel = NSLocalizedString("Forward", comment: "Accessibility Label for the browser toolbar Forward button")
        forwardButton.accessibilityHint = NSLocalizedString("Double tap and hold to open history", comment: "")
        longPressGestureForwardButton = UILongPressGestureRecognizer(target: self, action: "SELdidLongPressForward:")
        forwardButton.addGestureRecognizer(longPressGestureForwardButton)
        forwardButton.addTarget(self, action: "SELdidClickForward", forControlEvents: UIControlEvents.TouchUpInside)
        forwardButton.contentEdgeInsets = ButtonInset

        shareButton.setImage(UIImage(named: "send"), forState: .Normal)
        shareButton.accessibilityLabel = NSLocalizedString("Share", comment: "Accessibility Label for the browser toolbar Share button")
        shareButton.addTarget(self, action: "SELdidClickShare", forControlEvents: UIControlEvents.TouchUpInside)
        shareButton.contentEdgeInsets = ButtonInset

        bookmarkButton.setImage(UIImage(named: "bookmark"), forState: .Normal)
        bookmarkButton.accessibilityLabel = NSLocalizedString("Share", comment: "Accessibility Label for the browser toolbar Bookmark button")
        longPressGestureBookmarkButton = UILongPressGestureRecognizer(target: self, action: "SELdidLongPressBookmark:")
        bookmarkButton.addGestureRecognizer(longPressGestureBookmarkButton)
        bookmarkButton.addTarget(self, action: "SELdidClickBookmark", forControlEvents: UIControlEvents.TouchUpInside)
        bookmarkButton.contentEdgeInsets = ButtonInset

        addButtons(backButton, forwardButton, shareButton, bookmarkButton)
    }

    // This has to be here since init() calls it
    private override init(frame: CGRect) {
        // And these have to be initialized in here or the compiler will get angry
        backButton = UIButton()
        forwardButton = UIButton()
        shareButton = UIButton()
        bookmarkButton = UIButton()

        super.init(frame: frame)

        longPressGestureBackButton = UILongPressGestureRecognizer(target: self, action: "SELdidLongPressBack:")
        longPressGestureForwardButton = UILongPressGestureRecognizer(target: self, action: "SELdidLongPressForward:")
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        browserToolbarDelegate?.browserToolbarDidPressBack(self)
    }

    func SELdidLongPressBack(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Began {
            browserToolbarDelegate?.browserToolbarDidLongPressBack(self)
        }
    }

    func SELdidClickShare() {
        browserToolbarDelegate?.browserToolbarDidPressShare(self)
    }

    func SELdidClickForward() {
        browserToolbarDelegate?.browserToolbarDidPressForward(self)
    }

    func SELdidLongPressForward(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Began {
            browserToolbarDelegate?.browserToolbarDidLongPressForward(self)
        }
    }

    func SELdidClickBookmark() {
        browserToolbarDelegate?.browserToolbarDidPressBookmark(self)
    }

    func SELdidLongPressBookmark(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Began {
            browserToolbarDelegate?.browserToolbarDidLongPressBookmark(self)
        }
    }
}
