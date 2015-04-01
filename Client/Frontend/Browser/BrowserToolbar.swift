/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Snap

@objc
protocol BrowserToolbarProtocol {
    weak var browserToolbarDelegate: BrowserToolbarDelegate? { get set }
    var shareButton: UIButton { get }
    var bookmarkButton: UIButton { get }
    var forwardButton: UIButton { get }
    var backButton: UIButton { get }

    func updateBackStatus(canGoBack: Bool)
    func updateFowardStatus(canGoForward: Bool)
    func updateBookmarkStatus(isBookmarked: Bool)
}

@objc
protocol BrowserToolbarDelegate: class {
    func browserToolbarDidPressBack(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidPressForward(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidLongPressBack(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidLongPressForward(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidPressBookmark(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidLongPressBookmark(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidPressShare(browserToolbar: BrowserToolbarProtocol, button: UIButton)
}

@objc
public class BrowserToolbarHelper {
    let toolbar: BrowserToolbarProtocol

    init(toolbar: BrowserToolbarProtocol) {
        self.toolbar = toolbar
        let inset: CGFloat = UIScreen.mainScreen().traitCollection.verticalSizeClass == .Regular ? 10 : 2
        let ButtonInset = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)

        toolbar.backButton.setImage(UIImage(named: "back"), forState: .Normal)
        toolbar.backButton.setImage(UIImage(named: "backPressed"), forState: .Highlighted)
        toolbar.backButton.accessibilityLabel = NSLocalizedString("Back", comment: "Accessibility Label for the browser toolbar Back button")
        toolbar.backButton.accessibilityHint = NSLocalizedString("Double tap and hold to open history", comment: "")
        var longPressGestureBackButton = UILongPressGestureRecognizer(target: self, action: "SELdidLongPressBack:")
        toolbar.backButton.addGestureRecognizer(longPressGestureBackButton)
        toolbar.backButton.contentEdgeInsets = ButtonInset
        toolbar.backButton.addTarget(self, action: "SELdidClickBack", forControlEvents: UIControlEvents.TouchUpInside)

        toolbar.forwardButton.setImage(UIImage(named: "forward"), forState: .Normal)
        toolbar.forwardButton.setImage(UIImage(named: "forwardPressed"), forState: .Highlighted)
        toolbar.forwardButton.accessibilityLabel = NSLocalizedString("Forward", comment: "Accessibility Label for the browser toolbar Forward button")
        toolbar.forwardButton.accessibilityHint = NSLocalizedString("Double tap and hold to open history", comment: "")
        var longPressGestureForwardButton = UILongPressGestureRecognizer(target: self, action: "SELdidLongPressForward:")
        toolbar.forwardButton.addGestureRecognizer(longPressGestureForwardButton)
        toolbar.forwardButton.addTarget(self, action: "SELdidClickForward", forControlEvents: UIControlEvents.TouchUpInside)
        toolbar.forwardButton.contentEdgeInsets = ButtonInset

        toolbar.shareButton.setImage(UIImage(named: "send"), forState: .Normal)
        toolbar.shareButton.setImage(UIImage(named: "sendPressed"), forState: .Highlighted)
        toolbar.shareButton.accessibilityLabel = NSLocalizedString("Share", comment: "Accessibility Label for the browser toolbar Share button")
        toolbar.shareButton.addTarget(self, action: "SELdidClickShare", forControlEvents: UIControlEvents.TouchUpInside)
        toolbar.shareButton.contentEdgeInsets = ButtonInset

        toolbar.bookmarkButton.setImage(UIImage(named: "bookmark"), forState: .Normal)
        toolbar.bookmarkButton.setImage(UIImage(named: "bookmarked"), forState: UIControlState.Selected)
        toolbar.bookmarkButton.accessibilityLabel = NSLocalizedString("Bookmark", comment: "Accessibility Label for the browser toolbar Bookmark button")
        var longPressGestureBookmarkButton = UILongPressGestureRecognizer(target: self, action: "SELdidLongPressBookmark:")
        toolbar.bookmarkButton.addGestureRecognizer(longPressGestureBookmarkButton)
        toolbar.bookmarkButton.addTarget(self, action: "SELdidClickBookmark", forControlEvents: UIControlEvents.TouchUpInside)
        toolbar.bookmarkButton.contentEdgeInsets = ButtonInset
    }

    func SELdidClickBack() {
        toolbar.browserToolbarDelegate?.browserToolbarDidPressBack(toolbar, button: toolbar.backButton)
    }

    func SELdidLongPressBack(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Began {
            toolbar.browserToolbarDelegate?.browserToolbarDidLongPressBack(toolbar, button: toolbar.backButton)
        }
    }

    func SELdidClickShare() {
        toolbar.browserToolbarDelegate?.browserToolbarDidPressShare(toolbar, button: toolbar.shareButton)
    }

    func SELdidClickForward() {
        toolbar.browserToolbarDelegate?.browserToolbarDidPressForward(toolbar, button: toolbar.forwardButton)
    }

    func SELdidLongPressForward(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Began {
            toolbar.browserToolbarDelegate?.browserToolbarDidLongPressForward(toolbar, button: toolbar.forwardButton)
        }
    }

    func SELdidClickBookmark() {
        toolbar.browserToolbarDelegate?.browserToolbarDidPressBookmark(toolbar, button: toolbar.bookmarkButton)
    }

    func SELdidLongPressBookmark(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Began {
            toolbar.browserToolbarDelegate?.browserToolbarDidLongPressBookmark(toolbar, button: toolbar.bookmarkButton)
        }
    }
}

class BrowserToolbar: Toolbar, BrowserToolbarProtocol {
    weak var browserToolbarDelegate: BrowserToolbarDelegate?

    let shareButton: UIButton
    let bookmarkButton: UIButton
    let forwardButton: UIButton
    let backButton: UIButton
    var helper: BrowserToolbarHelper?

    override init() {
        backButton = UIButton()
        forwardButton = UIButton()
        shareButton = UIButton()
        bookmarkButton = UIButton()

        super.init()

        self.helper = BrowserToolbarHelper(toolbar: self)
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
        bookmarkButton.selected = isBookmarked
    }
}
