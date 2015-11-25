/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit

@objc
protocol BrowserToolbarProtocol {
    weak var browserToolbarDelegate: BrowserToolbarDelegate? { get set }
    var shareButton: UIButton { get }
    var bookmarkButton: UIButton { get }
    var forwardButton: UIButton { get }
    var backButton: UIButton { get }
    var stopReloadButton: UIButton { get }
    var findInPageButton: UIButton { get }
    var actionButtons: [UIButton] { get }

    func updateBackStatus(canGoBack: Bool)
    func updateForwardStatus(canGoForward: Bool)
    func updateBookmarkStatus(isBookmarked: Bool)
    func updateReloadStatus(isLoading: Bool)
    func updatePageStatus(isWebPage isWebPage: Bool)
}

@objc
protocol BrowserToolbarDelegate: class {
    func browserToolbarDidPressBack(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidPressForward(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidLongPressBack(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidLongPressForward(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidPressReload(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidLongPressReload(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidPressStop(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidPressBookmark(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidLongPressBookmark(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidPressShare(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidPressFindInPage(browserToolbar: BrowserToolbarProtocol, button: UIButton)
}

@objc
public class BrowserToolbarHelper: NSObject {
    let toolbar: BrowserToolbarProtocol

    let ImageReload = UIImage(named: "reload")
    let ImageReloadPressed = UIImage(named: "reloadPressed")
    let ImageStop = UIImage(named: "stop")
    let ImageStopPressed = UIImage(named: "stopPressed")

    var buttonTintColor = UIColor.darkGrayColor() {
        didSet {
            setTintColor(buttonTintColor, forButtons: toolbar.actionButtons)
        }
    }

    var loading: Bool = false {
        didSet {
            if loading {
                toolbar.stopReloadButton.setImage(ImageStop, forState: .Normal)
                toolbar.stopReloadButton.setImage(ImageStopPressed, forState: .Highlighted)
                toolbar.stopReloadButton.accessibilityLabel = NSLocalizedString("Stop", comment: "Accessibility Label for the browser toolbar Stop button")
            } else {
                toolbar.stopReloadButton.setImage(ImageReload, forState: .Normal)
                toolbar.stopReloadButton.setImage(ImageReloadPressed, forState: .Highlighted)
                toolbar.stopReloadButton.accessibilityLabel = NSLocalizedString("Reload", comment: "Accessibility Label for the browser toolbar Reload button")
            }
        }
    }

    private func setTintColor(color: UIColor, forButtons buttons: [UIButton]) {
        buttons.forEach { $0.tintColor = color }
    }

    init(toolbar: BrowserToolbarProtocol) {
        self.toolbar = toolbar
        super.init()

        toolbar.backButton.setImage(UIImage(named: "back"), forState: .Normal)
        toolbar.backButton.setImage(UIImage(named: "backPressed"), forState: .Highlighted)
        toolbar.backButton.accessibilityLabel = NSLocalizedString("Back", comment: "Accessibility Label for the browser toolbar Back button")
        //toolbar.backButton.accessibilityHint = NSLocalizedString("Double tap and hold to open history", comment: "")
        let longPressGestureBackButton = UILongPressGestureRecognizer(target: self, action: "SELdidLongPressBack:")
        toolbar.backButton.addGestureRecognizer(longPressGestureBackButton)
        toolbar.backButton.addTarget(self, action: "SELdidClickBack", forControlEvents: UIControlEvents.TouchUpInside)

        toolbar.forwardButton.setImage(UIImage(named: "forward"), forState: .Normal)
        toolbar.forwardButton.setImage(UIImage(named: "forwardPressed"), forState: .Highlighted)
        toolbar.forwardButton.accessibilityLabel = NSLocalizedString("Forward", comment: "Accessibility Label for the browser toolbar Forward button")
        //toolbar.forwardButton.accessibilityHint = NSLocalizedString("Double tap and hold to open history", comment: "")
        let longPressGestureForwardButton = UILongPressGestureRecognizer(target: self, action: "SELdidLongPressForward:")
        toolbar.forwardButton.addGestureRecognizer(longPressGestureForwardButton)
        toolbar.forwardButton.addTarget(self, action: "SELdidClickForward", forControlEvents: UIControlEvents.TouchUpInside)

        toolbar.stopReloadButton.setImage(UIImage(named: "reload"), forState: .Normal)
        toolbar.stopReloadButton.setImage(UIImage(named: "reloadPressed"), forState: .Highlighted)
        toolbar.stopReloadButton.accessibilityLabel = NSLocalizedString("Reload", comment: "Accessibility Label for the browser toolbar Reload button")
        let longPressGestureStopReloadButton = UILongPressGestureRecognizer(target: self, action: "SELdidLongPressStopReload:")
        toolbar.stopReloadButton.addGestureRecognizer(longPressGestureStopReloadButton)
        toolbar.stopReloadButton.addTarget(self, action: "SELdidClickStopReload", forControlEvents: UIControlEvents.TouchUpInside)

        toolbar.shareButton.setImage(UIImage(named: "send"), forState: .Normal)
        toolbar.shareButton.setImage(UIImage(named: "sendPressed"), forState: .Highlighted)
        toolbar.shareButton.accessibilityLabel = NSLocalizedString("Share", comment: "Accessibility Label for the browser toolbar Share button")
        toolbar.shareButton.addTarget(self, action: "SELdidClickShare", forControlEvents: UIControlEvents.TouchUpInside)
        toolbar.bookmarkButton.contentMode = UIViewContentMode.Center

        toolbar.bookmarkButton.setImage(UIImage(named: "bookmark"), forState: .Normal)
        toolbar.bookmarkButton.setImage(UIImage(named: "bookmarked"), forState: UIControlState.Selected)
        toolbar.bookmarkButton.accessibilityLabel = NSLocalizedString("Bookmark", comment: "Accessibility Label for the browser toolbar Bookmark button")
        let longPressGestureBookmarkButton = UILongPressGestureRecognizer(target: self, action: "SELdidLongPressBookmark:")
        toolbar.bookmarkButton.addGestureRecognizer(longPressGestureBookmarkButton)
        toolbar.bookmarkButton.addTarget(self, action: "SELdidClickBookmark", forControlEvents: UIControlEvents.TouchUpInside)

        toolbar.findInPageButton.setTitle("find", forState: UIControlState.Normal)
        toolbar.findInPageButton.addTarget(self, action: "SELdidClickFindInPage", forControlEvents: UIControlEvents.TouchUpInside)

        setTintColor(buttonTintColor, forButtons: toolbar.actionButtons)
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

    func SELdidClickFindInPage() {
        toolbar.browserToolbarDelegate?.browserToolbarDidPressFindInPage(toolbar, button: toolbar.bookmarkButton)
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

    func SELdidLongPressStopReload(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Began && !loading {
            toolbar.browserToolbarDelegate?.browserToolbarDidLongPressReload(toolbar, button: toolbar.stopReloadButton)
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
    let findInPageButton: UIButton
    let actionButtons: [UIButton]

    var helper: BrowserToolbarHelper?

    // This has to be here since init() calls it
    private override init(frame: CGRect) {
        // And these have to be initialized in here or the compiler will get angry
        backButton = UIButton()
        forwardButton = UIButton()
        stopReloadButton = UIButton()
        shareButton = UIButton()
        bookmarkButton = UIButton()
        findInPageButton = UIButton()
        actionButtons = [backButton, forwardButton, stopReloadButton, shareButton, bookmarkButton, findInPageButton]

        super.init(frame: frame)

        self.helper = BrowserToolbarHelper(toolbar: self)

        addButtons(backButton, forwardButton, stopReloadButton, shareButton, bookmarkButton, findInPageButton)

        accessibilityNavigationStyle = .Combined
        accessibilityLabel = NSLocalizedString("Navigation Toolbar", comment: "Accessibility label for the navigation toolbar displayed at the bottom of the screen.")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateBackStatus(canGoBack: Bool) {
        backButton.enabled = canGoBack
    }

    func updateForwardStatus(canGoForward: Bool) {
        forwardButton.enabled = canGoForward
    }

    func updateBookmarkStatus(isBookmarked: Bool) {
        bookmarkButton.selected = isBookmarked
    }

    func updateReloadStatus(isLoading: Bool) {
        helper?.updateReloadStatus(isLoading)
    }

    func updatePageStatus(isWebPage isWebPage: Bool) {
        bookmarkButton.enabled = isWebPage
        stopReloadButton.enabled = isWebPage
        shareButton.enabled = isWebPage
    }

    override func drawRect(rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            drawLine(context, start: CGPoint(x: 0, y: 0), end: CGPoint(x: frame.width, y: 0))
        }
    }

    private func drawLine(context: CGContextRef, start: CGPoint, end: CGPoint) {
        CGContextSetStrokeColorWithColor(context, UIColor.blackColor().colorWithAlphaComponent(0.05).CGColor)
        CGContextSetLineWidth(context, 2)
        CGContextMoveToPoint(context, start.x, start.y)
        CGContextAddLineToPoint(context, end.x, end.y)
        CGContextStrokePath(context)
    }
}

// MARK: UIAppearance
extension BrowserToolbar {
    dynamic var actionButtonTintColor: UIColor? {
        get { return helper?.buttonTintColor }
        set {
            guard let value = newValue else { return }
            helper?.buttonTintColor = value
        }
    }
}
