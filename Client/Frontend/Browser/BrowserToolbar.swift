/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Shared
import XCGLogger

private let log = Logger.browserLogger

@objc
protocol BrowserToolbarProtocol {
    weak var browserToolbarDelegate: BrowserToolbarDelegate? { get set }
    var shareButton: UIButton { get }
    var bookmarkButton: UIButton { get }
    var menuButton: UIButton { get }
    var forwardButton: UIButton { get }
    var backButton: UIButton { get }
    var stopReloadButton: UIButton { get }
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
    func browserToolbarDidPressMenu(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidPressBookmark(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidLongPressBookmark(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidPressShare(browserToolbar: BrowserToolbarProtocol, button: UIButton)
}

@objc
public class BrowserToolbarHelper: NSObject {
    let toolbar: BrowserToolbarProtocol

    let ImageReload = UIImage.templateImageNamed("bottomNav-refresh")
    let ImageReloadPressed = UIImage.templateImageNamed("bottomNav-refresh")
    let ImageStop = UIImage.templateImageNamed("stop")
    let ImageStopPressed = UIImage.templateImageNamed("stopPressed")

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

        toolbar.backButton.setImage(UIImage.templateImageNamed("bottomNav-back"), forState: .Normal)
        toolbar.backButton.setImage(UIImage(named: "bottomNav-backEngaged"), forState: .Highlighted)
        toolbar.backButton.accessibilityLabel = NSLocalizedString("Back", comment: "Accessibility Label for the browser toolbar Back button")
        //toolbar.backButton.accessibilityHint = NSLocalizedString("Double tap and hold to open history", comment: "")
        let longPressGestureBackButton = UILongPressGestureRecognizer(target: self, action: #selector(BrowserToolbarHelper.SELdidLongPressBack(_:)))
        toolbar.backButton.addGestureRecognizer(longPressGestureBackButton)
        toolbar.backButton.addTarget(self, action: #selector(BrowserToolbarHelper.SELdidClickBack), forControlEvents: UIControlEvents.TouchUpInside)

        toolbar.forwardButton.setImage(UIImage.templateImageNamed("bottomNav-forward"), forState: .Normal)
        toolbar.forwardButton.setImage(UIImage(named: "bottomNav-forwardEngaged"), forState: .Highlighted)
        toolbar.forwardButton.accessibilityLabel = NSLocalizedString("Forward", comment: "Accessibility Label for the browser toolbar Forward button")
        //toolbar.forwardButton.accessibilityHint = NSLocalizedString("Double tap and hold to open history", comment: "")
        let longPressGestureForwardButton = UILongPressGestureRecognizer(target: self, action: #selector(BrowserToolbarHelper.SELdidLongPressForward(_:)))
        toolbar.forwardButton.addGestureRecognizer(longPressGestureForwardButton)
        toolbar.forwardButton.addTarget(self, action: #selector(BrowserToolbarHelper.SELdidClickForward), forControlEvents: UIControlEvents.TouchUpInside)

        toolbar.stopReloadButton.setImage(UIImage.templateImageNamed("bottomNav-refresh"), forState: .Normal)
        toolbar.stopReloadButton.setImage(UIImage(named: "bottomNav-refreshEngaged"), forState: .Highlighted)
        toolbar.stopReloadButton.accessibilityLabel = NSLocalizedString("Reload", comment: "Accessibility Label for the browser toolbar Reload button")
        let longPressGestureStopReloadButton = UILongPressGestureRecognizer(target: self, action: #selector(BrowserToolbarHelper.SELdidLongPressStopReload(_:)))
        toolbar.stopReloadButton.addGestureRecognizer(longPressGestureStopReloadButton)
        toolbar.stopReloadButton.addTarget(self, action: #selector(BrowserToolbarHelper.SELdidClickStopReload), forControlEvents: UIControlEvents.TouchUpInside)

        toolbar.shareButton.setImage(UIImage.templateImageNamed("bottomNav-send"), forState: .Normal)
        toolbar.shareButton.setImage(UIImage(named: "bottomNav-sendEngaged"), forState: .Highlighted)
        toolbar.shareButton.accessibilityLabel = NSLocalizedString("Share", comment: "Accessibility Label for the browser toolbar Share button")
        toolbar.shareButton.addTarget(self, action: #selector(BrowserToolbarHelper.SELdidClickShare), forControlEvents: UIControlEvents.TouchUpInside)

        if AppConstants.MOZ_MENU {
            toolbar.menuButton.contentMode = UIViewContentMode.Center
            toolbar.menuButton.setImage(UIImage.templateImageNamed("bottomNav-menu"), forState: .Normal)
            toolbar.menuButton.accessibilityLabel = NSLocalizedString("Menu", comment: "Accessibility Label for the browser toolbar Menu button")
            toolbar.menuButton.addTarget(self, action: #selector(BrowserToolbarHelper.SELdidClickMenu), forControlEvents: UIControlEvents.TouchUpInside)
        } else {
            toolbar.bookmarkButton.contentMode = UIViewContentMode.Center
            toolbar.bookmarkButton.setImage(UIImage(named: "bookmark"), forState: .Normal)
            toolbar.bookmarkButton.setImage(UIImage(named: "bookmarked"), forState: UIControlState.Selected)
            toolbar.bookmarkButton.setImage(UIImage(named: "bookmarkHighlighted"), forState: UIControlState.Highlighted)
            toolbar.bookmarkButton.accessibilityLabel = NSLocalizedString("Bookmark", comment: "Accessibility Label for the browser toolbar Bookmark button")
            let longPressGestureBookmarkButton = UILongPressGestureRecognizer(target: self, action: #selector(BrowserToolbarHelper.SELdidLongPressBookmark(_:)))
            toolbar.bookmarkButton.addGestureRecognizer(longPressGestureBookmarkButton)
            toolbar.bookmarkButton.addTarget(self, action: #selector(BrowserToolbarHelper.SELdidClickBookmark), forControlEvents: UIControlEvents.TouchUpInside)
        }

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

    func SELdidLongPressBookmark(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Began {
            toolbar.browserToolbarDelegate?.browserToolbarDidLongPressBookmark(toolbar, button: toolbar.bookmarkButton)
        }
    }

    func SELdidClickMenu() {
        toolbar.browserToolbarDelegate?.browserToolbarDidPressMenu(toolbar, button: toolbar.menuButton)
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
    let menuButton: UIButton
    let forwardButton: UIButton
    let backButton: UIButton
    let stopReloadButton: UIButton
    let actionButtons: [UIButton]

    var helper: BrowserToolbarHelper?

    static let Themes: [String: Theme] = {
        var themes = [String: Theme]()
        var theme = Theme()
        theme.buttonTintColor = UIConstants.PrivateModeActionButtonTintColor
        themes[Theme.PrivateMode] = theme

        theme = Theme()
        theme.buttonTintColor = UIColor.darkGrayColor()
        themes[Theme.NormalMode] = theme

        return themes
    }()

    // This has to be here since init() calls it
    private override init(frame: CGRect) {
        // And these have to be initialized in here or the compiler will get angry
        backButton = UIButton()
        backButton.accessibilityIdentifier = "BrowserToolbar.backButton"
        forwardButton = UIButton()
        forwardButton.accessibilityIdentifier = "BrowserToolbar.forwardButton"
        stopReloadButton = UIButton()
        stopReloadButton.accessibilityIdentifier = "BrowserToolbar.stopReloadButton"
        shareButton = UIButton()
        shareButton.accessibilityIdentifier = "BrowserToolbar.shareButton"
        bookmarkButton = UIButton()
        bookmarkButton.accessibilityIdentifier = "BrowserToolbar.bookmarkButton"
        menuButton = UIButton()
        menuButton.accessibilityIdentifier = "BrowserToolbar.menuButton"
        if AppConstants.MOZ_MENU {
            actionButtons = [backButton, forwardButton, menuButton, stopReloadButton, shareButton]
        } else {
            actionButtons = [backButton, forwardButton, stopReloadButton, shareButton, bookmarkButton]
        }

        super.init(frame: frame)

        self.helper = BrowserToolbarHelper(toolbar: self)

        if AppConstants.MOZ_MENU {
            addButtons(backButton, forwardButton, menuButton, stopReloadButton, shareButton)
        } else {
            addButtons(backButton, forwardButton, stopReloadButton, shareButton, bookmarkButton)
        }

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
        if AppConstants.MOZ_MENU {
            menuButton.enabled = isWebPage
        } else {
            bookmarkButton.enabled = isWebPage
        }
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

extension BrowserToolbar: Themeable {
    func applyTheme(themeName: String) {
        guard let theme = BrowserToolbar.Themes[themeName] else {
            log.error("Unable to apply unknown theme \(themeName)")
            return
        }
        actionButtonTintColor = theme.buttonTintColor!
    }
}
