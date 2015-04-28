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
    var stopReloadButton: UIButton { get }

    func updateBackStatus(canGoBack: Bool)
    func updateFowardStatus(canGoForward: Bool)
    func updateBookmarkStatus(isBookmarked: Bool)
    func updateReloadStatus(isLoading: Bool)
}

@objc
protocol BrowserToolbarDelegate: class {
    func browserToolbarDidPressBack(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidPressForward(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidLongPressBack(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidLongPressForward(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidPressReload(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidPressStop(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidPressBookmark(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidLongPressBookmark(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidPressShare(browserToolbar: BrowserToolbarProtocol, button: UIButton)
}

@objc
public class BrowserToolbarHelper {
    let toolbar: BrowserToolbarProtocol

    private let ButtonInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    private let NavButtonInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)

    let ImageReload = UIImage(named: "reload")
    let ImageReloadPressed = UIImage(named: "reloadPressed")
    let ImageStop = UIImage(named: "stop")
    let ImageStopPressed = UIImage(named: "stopPressed")

    var loading: Bool = false {
        didSet {
            if loading {
                toolbar.stopReloadButton.setImage(ImageStop, forState: .Normal)
                toolbar.stopReloadButton.setImage(ImageStopPressed, forState: .Highlighted)
                toolbar.stopReloadButton.accessibilityLabel = NSLocalizedString("Stop", comment: "Accessibility Label for the browser toolbar Stop button")
                toolbar.stopReloadButton.accessibilityHint = NSLocalizedString("Tap to stop loading the page", comment: "")
            } else {
                toolbar.stopReloadButton.setImage(ImageReload, forState: .Normal)
                toolbar.stopReloadButton.setImage(ImageReloadPressed, forState: .Highlighted)
                toolbar.stopReloadButton.accessibilityLabel = NSLocalizedString("Reload", comment: "Accessibility Label for the browser toolbar Reload button")
                toolbar.stopReloadButton.accessibilityHint = NSLocalizedString("Tap to reload the page", comment: "")
            }
        }
    }

    init(toolbar: BrowserToolbarProtocol) {
        self.toolbar = toolbar
        let inset: CGFloat = UIScreen.mainScreen().traitCollection.verticalSizeClass == .Regular ? 10 : 2
        let ButtonInset = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)

        toolbar.backButton.setImage(UIImage(named: "back"), forState: .Normal)
        toolbar.backButton.setImage(UIImage(named: "backPressed"), forState: .Highlighted)
        toolbar.backButton.accessibilityLabel = NSLocalizedString("Back", comment: "Accessibility Label for the browser toolbar Back button")
        //toolbar.backButton.accessibilityHint = NSLocalizedString("Double tap and hold to open history", comment: "")
        var longPressGestureBackButton = UILongPressGestureRecognizer(target: self, action: "SELdidLongPressBack:")
        toolbar.backButton.addGestureRecognizer(longPressGestureBackButton)
        toolbar.backButton.contentEdgeInsets = NavButtonInset
        toolbar.backButton.addTarget(self, action: "SELdidClickBack", forControlEvents: UIControlEvents.TouchUpInside)

        toolbar.forwardButton.setImage(UIImage(named: "forward"), forState: .Normal)
        toolbar.forwardButton.setImage(UIImage(named: "forwardPressed"), forState: .Highlighted)
        toolbar.forwardButton.accessibilityLabel = NSLocalizedString("Forward", comment: "Accessibility Label for the browser toolbar Forward button")
        //toolbar.forwardButton.accessibilityHint = NSLocalizedString("Double tap and hold to open history", comment: "")
        var longPressGestureForwardButton = UILongPressGestureRecognizer(target: self, action: "SELdidLongPressForward:")
        toolbar.forwardButton.addGestureRecognizer(longPressGestureForwardButton)
        toolbar.forwardButton.addTarget(self, action: "SELdidClickForward", forControlEvents: UIControlEvents.TouchUpInside)
        toolbar.forwardButton.contentEdgeInsets = NavButtonInset

        toolbar.stopReloadButton.setImage(UIImage(named: "reload"), forState: .Normal)
        toolbar.stopReloadButton.setImage(UIImage(named: "reloadPressed"), forState: .Highlighted)
        toolbar.stopReloadButton.accessibilityLabel = NSLocalizedString("Reload", comment: "Accessibility Label for the browser toolbar Reload button")
        toolbar.stopReloadButton.accessibilityHint = NSLocalizedString("Tap to reload page", comment: "")
        toolbar.stopReloadButton.addTarget(self, action: "SELdidClickStopReload", forControlEvents: UIControlEvents.TouchUpInside)
        toolbar.stopReloadButton.contentEdgeInsets = NavButtonInset

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

    func SELdidClickStopReload() {
        if loading {
            toolbar.browserToolbarDelegate?.browserToolbarDidPressStop(toolbar, button: toolbar.stopReloadButton)
        } else {
            toolbar.browserToolbarDelegate?.browserToolbarDidPressReload(toolbar, button: toolbar.stopReloadButton)
        }
    }

    func updateReloadStatus(isLoading: Bool) {
        loading = isLoading
    }
}


class BrowserToolbar: Toolbar, BrowserToolbarProtocol {
    weak var browserToolbarDelegate: BrowserToolbarDelegate?

    let shareButton: UIButton
    let bookmarkButton: UIButton
    let forwardButton: UIButton
    let backButton: UIButton
    let stopReloadButton: UIButton

    var helper: BrowserToolbarHelper?

    // This has to be here since init() calls it
    private override init(frame: CGRect) {
        // And these have to be initialized in here or the compiler will get angry
        backButton = UIButton()
        forwardButton = UIButton()
        stopReloadButton = UIButton()
        shareButton = UIButton()
        bookmarkButton = UIButton()

        super.init(frame: frame)

        self.helper = BrowserToolbarHelper(toolbar: self)

        addButtons(backButton, forwardButton, stopReloadButton, shareButton, bookmarkButton)

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

    func updateReloadStatus(isLoading: Bool) {
        helper?.updateReloadStatus(isLoading)
    }

}
