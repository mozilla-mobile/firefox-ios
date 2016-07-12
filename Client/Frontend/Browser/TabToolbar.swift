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
protocol TabToolbarProtocol {
    weak var tabToolbarDelegate: TabToolbarDelegate? { get set }
    var shareButton: UIButton { get }
    var bookmarkButton: UIButton { get }
    var menuButton: UIButton { get }
    var forwardButton: UIButton { get }
    var backButton: UIButton { get }
    var stopReloadButton: UIButton { get }
    var homePageButton: UIButton { get }
    var actionButtons: [UIButton] { get }

    func updateBackStatus(_ canGoBack: Bool)
    func updateForwardStatus(_ canGoForward: Bool)
    func updateBookmarkStatus(_ isBookmarked: Bool)
    func updateReloadStatus(loading isLoading: Bool)
    func updatePageStatus(isWebPage: Bool)
}

@objc
protocol TabToolbarDelegate: class {
    func tabToolbarDidPressBack(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressForward(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressBack(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressForward(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressReload(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressReload(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressStop(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressMenu(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressBookmark(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressBookmark(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressShare(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressHomePage(_ tabToolbar: TabToolbarProtocol, button: UIButton)
}

@objc
public class TabToolbarHelper: NSObject {
    let toolbar: TabToolbarProtocol

    let ImageReload = UIImage.templateImageNamed("bottomNav-refresh")
    let ImageReloadPressed = UIImage.templateImageNamed("bottomNav-refresh")
    let ImageStop = UIImage.templateImageNamed("stop")
    let ImageStopPressed = UIImage.templateImageNamed("stopPressed")

    var buttonTintColor = UIColor.darkGray() {
        didSet {
            setTint(color: buttonTintColor, forButtons: toolbar.actionButtons)
        }
    }

    var loading: Bool = false {
        didSet {
            if loading {
                toolbar.stopReloadButton.setImage(ImageStop, for: .Normal)
                toolbar.stopReloadButton.setImage(ImageStopPressed, for: .Highlighted)
                toolbar.stopReloadButton.accessibilityLabel = NSLocalizedString("Stop", comment: "Accessibility Label for the tab toolbar Stop button")
            } else {
                toolbar.stopReloadButton.setImage(ImageReload, for: .Normal)
                toolbar.stopReloadButton.setImage(ImageReloadPressed, for: .Highlighted)
                toolbar.stopReloadButton.accessibilityLabel = NSLocalizedString("Reload", comment: "Accessibility Label for the tab toolbar Reload button")
            }
        }
    }

    private func setTint(color: UIColor, forButtons buttons: [UIButton]) {
        buttons.forEach { $0.tintColor = color }
    }

    init(toolbar: TabToolbarProtocol) {
        self.toolbar = toolbar
        super.init()

        toolbar.backButton.setImage(UIImage.templateImageNamed("bottomNav-back"), for: .Normal)
        toolbar.backButton.setImage(UIImage(named: "bottomNav-backEngaged"), for: .highlighted)
        toolbar.backButton.accessibilityLabel = NSLocalizedString("Back", comment: "Accessibility label for the Back button in the tab toolbar.")
        //toolbar.backButton.accessibilityHint = NSLocalizedString("Double tap and hold to open history", comment: "Accessibility hint, associated to the Back button in the tab toolbar, used by assistive technology to describe the result of a double tap.")
        let longPressGestureBackButton = UILongPressGestureRecognizer(target: self, action: #selector(TabToolbarHelper.SELdidLongPressBack(_:)))
        toolbar.backButton.addGestureRecognizer(longPressGestureBackButton)
        toolbar.backButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickBack), for: UIControlEvents.touchUpInside)

        toolbar.forwardButton.setImage(UIImage.templateImageNamed("bottomNav-forward"), for: .Normal)
        toolbar.forwardButton.setImage(UIImage(named: "bottomNav-forwardEngaged"), for: .highlighted)
        toolbar.forwardButton.accessibilityLabel = NSLocalizedString("Forward", comment: "Accessibility Label for the tab toolbar Forward button")
        //toolbar.forwardButton.accessibilityHint = NSLocalizedString("Double tap and hold to open history", comment: "Accessibility hint, associated to the Back button in the tab toolbar, used by assistive technology to describe the result of a double tap.")
        let longPressGestureForwardButton = UILongPressGestureRecognizer(target: self, action: #selector(TabToolbarHelper.SELdidLongPressForward(_:)))
        toolbar.forwardButton.addGestureRecognizer(longPressGestureForwardButton)
        toolbar.forwardButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickForward), for: UIControlEvents.touchUpInside)

        toolbar.stopReloadButton.setImage(UIImage.templateImageNamed("bottomNav-refresh"), for: .Normal)
        toolbar.stopReloadButton.setImage(UIImage(named: "bottomNav-refreshEngaged"), for: .highlighted)
        toolbar.stopReloadButton.accessibilityLabel = NSLocalizedString("Reload", comment: "Accessibility Label for the tab toolbar Reload button")
        let longPressGestureStopReloadButton = UILongPressGestureRecognizer(target: self, action: #selector(TabToolbarHelper.SELdidLongPressStopReload(_:)))
        toolbar.stopReloadButton.addGestureRecognizer(longPressGestureStopReloadButton)
        toolbar.stopReloadButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickStopReload), for: UIControlEvents.touchUpInside)

        toolbar.shareButton.setImage(UIImage.templateImageNamed("bottomNav-send"), for: .Normal)
        toolbar.shareButton.setImage(UIImage(named: "bottomNav-sendEngaged"), for: .highlighted)
        toolbar.shareButton.accessibilityLabel = NSLocalizedString("Share", comment: "Accessibility Label for the tab toolbar Share button")
        toolbar.shareButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickShare), for: UIControlEvents.touchUpInside)


        toolbar.homePageButton.setImage(UIImage.templateImageNamed("menu-Home"), for: .Normal)
        toolbar.homePageButton.setImage(UIImage(named: "menu-Home-Engaged"), for: .highlighted)
        toolbar.homePageButton.accessibilityLabel = NSLocalizedString("Toolbar.OpenHomePage.AccessibilityLabel", value: "Homepage", comment: "Accessibility Label for the tab toolbar Homepage button")
        toolbar.homePageButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickHomePage), for: UIControlEvents.touchUpInside)

        if AppConstants.MOZ_MENU {
            toolbar.menuButton.contentMode = UIViewContentMode.center
            toolbar.menuButton.setImage(UIImage.templateImageNamed("bottomNav-menu"), for: .Normal)
            toolbar.menuButton.accessibilityLabel = AppMenuConfiguration.MenuButtonAccessibilityLabel
            toolbar.menuButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickMenu), for: UIControlEvents.touchUpInside)
        } else {
            toolbar.bookmarkButton.contentMode = UIViewContentMode.center
            toolbar.bookmarkButton.setImage(UIImage(named: "bookmark"), for: UIControlState())
            toolbar.bookmarkButton.setImage(UIImage(named: "bookmarked"), for: UIControlState.selected)
            toolbar.bookmarkButton.setImage(UIImage(named: "bookmarkHighlighted"), for: UIControlState.highlighted)
            toolbar.bookmarkButton.accessibilityLabel = NSLocalizedString("Bookmark", comment: "Accessibility Label for the tab toolbar Bookmark button")
            let longPressGestureBookmarkButton = UILongPressGestureRecognizer(target: self, action: #selector(TabToolbarHelper.SELdidLongPressBookmark(_:)))
            toolbar.bookmarkButton.addGestureRecognizer(longPressGestureBookmarkButton)
            toolbar.bookmarkButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickBookmark), for: UIControlEvents.touchUpInside)
        }

        setTint(color: buttonTintColor, forButtons: toolbar.actionButtons)
    }

    func SELdidClickBack() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressBack(toolbar, button: toolbar.backButton)
    }

    func SELdidLongPressBack(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.began {
            toolbar.tabToolbarDelegate?.tabToolbarDidLongPressBack(toolbar, button: toolbar.backButton)
        }
    }

    func SELdidClickShare() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressShare(toolbar, button: toolbar.shareButton)
    }

    func SELdidClickForward() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressForward(toolbar, button: toolbar.forwardButton)
    }

    func SELdidLongPressForward(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.began {
            toolbar.tabToolbarDelegate?.tabToolbarDidLongPressForward(toolbar, button: toolbar.forwardButton)
        }
    }

    func SELdidClickBookmark() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressBookmark(toolbar, button: toolbar.bookmarkButton)
    }

    func SELdidLongPressBookmark(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.began {
            toolbar.tabToolbarDelegate?.tabToolbarDidLongPressBookmark(toolbar, button: toolbar.bookmarkButton)
        }
    }

    func SELdidClickMenu() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressMenu(toolbar, button: toolbar.menuButton)
    }

    func SELdidClickStopReload() {
        if loading {
            toolbar.tabToolbarDelegate?.tabToolbarDidPressStop(toolbar, button: toolbar.stopReloadButton)
        } else {
            toolbar.tabToolbarDelegate?.tabToolbarDidPressReload(toolbar, button: toolbar.stopReloadButton)
        }
    }

    func SELdidLongPressStopReload(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.began && !loading {
            toolbar.tabToolbarDelegate?.tabToolbarDidLongPressReload(toolbar, button: toolbar.stopReloadButton)
        }
    }

    func SELdidClickHomePage() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressHomePage(toolbar, button: toolbar.homePageButton)
    }

    func updateReloadStatus(isLoading: Bool) {
        loading = isLoading
    }
}

class TabToolbar: Toolbar, TabToolbarProtocol {
    weak var tabToolbarDelegate: TabToolbarDelegate?

    let shareButton: UIButton
    let bookmarkButton: UIButton
    let menuButton: UIButton
    let forwardButton: UIButton
    let backButton: UIButton
    let stopReloadButton: UIButton
    let homePageButton: UIButton
    let actionButtons: [UIButton]

    var helper: TabToolbarHelper?

    static let Themes: [String: Theme] = {
        var themes = [String: Theme]()
        var theme = Theme()
        theme.buttonTintColor = UIConstants.PrivateModeActionButtonTintColor
        themes[Theme.PrivateMode] = theme

        theme = Theme()
        theme.buttonTintColor = UIColor.darkGray()
        themes[Theme.NormalMode] = theme

        return themes
    }()

    // This has to be here since init() calls it
    private override init(frame: CGRect) {
        // And these have to be initialized in here or the compiler will get angry
        backButton = UIButton()
        backButton.accessibilityIdentifier = "TabToolbar.backButton"
        forwardButton = UIButton()
        forwardButton.accessibilityIdentifier = "TabToolbar.forwardButton"
        stopReloadButton = UIButton()
        stopReloadButton.accessibilityIdentifier = "TabToolbar.stopReloadButton"
        shareButton = UIButton()
        shareButton.accessibilityIdentifier = "TabToolbar.shareButton"
        bookmarkButton = UIButton()
        bookmarkButton.accessibilityIdentifier = "TabToolbar.bookmarkButton"
        menuButton = UIButton()
        menuButton.accessibilityIdentifier = "TabToolbar.menuButton"
        homePageButton = UIButton()
        menuButton.accessibilityIdentifier = "TabToolbar.homePageButton"
        if AppConstants.MOZ_MENU {
            actionButtons = [backButton, forwardButton, menuButton, stopReloadButton, shareButton, homePageButton]
        } else {
            actionButtons = [backButton, forwardButton, stopReloadButton, shareButton, bookmarkButton]
        }

        super.init(frame: frame)

        self.helper = TabToolbarHelper(toolbar: self)

        if AppConstants.MOZ_MENU {
            addButtons(backButton, forwardButton, menuButton, stopReloadButton, shareButton, homePageButton)
        } else {
            addButtons(backButton, forwardButton, stopReloadButton, shareButton, bookmarkButton)
        }

        accessibilityNavigationStyle = .combined
        accessibilityLabel = NSLocalizedString("Navigation Toolbar", comment: "Accessibility label for the navigation toolbar displayed at the bottom of the screen.")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateBackStatus(_ canGoBack: Bool) {
        backButton.isEnabled = canGoBack
    }

    func updateForwardStatus(_ canGoForward: Bool) {
        forwardButton.isEnabled = canGoForward
    }

    func updateBookmarkStatus(_ isBookmarked: Bool) {
        bookmarkButton.isSelected = isBookmarked
    }

    func updateReloadStatus(isLoading: Bool) {
        helper?.updateReloadStatus(isLoading: isLoading)
    }

    func updatePageStatus(isWebPage: Bool) {
        if !AppConstants.MOZ_MENU {
            bookmarkButton.isEnabled = isWebPage
        }
        stopReloadButton.isEnabled = isWebPage
        shareButton.isEnabled = isWebPage
    }

    override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            drawLine(context, start: CGPoint(x: 0, y: 0), end: CGPoint(x: frame.width, y: 0))
        }
    }

    private func drawLine(_ context: CGContext, start: CGPoint, end: CGPoint) {
        context.setStrokeColor(UIColor.black().withAlphaComponent(0.05).cgColor)
        context.setLineWidth(2)
        context.moveTo(x: start.x, y: start.y)
        context.addLineTo(x: end.x, y: end.y)
        context.strokePath()
    }
}

// MARK: UIAppearance
extension TabToolbar {
    dynamic var actionButtonTintColor: UIColor? {
        get { return helper?.buttonTintColor }
        set {
            guard let value = newValue else { return }
            helper?.buttonTintColor = value
        }
    }
}

extension TabToolbar: Themeable {
    func applyTheme(_ themeName: String) {
        guard let theme = TabToolbar.Themes[themeName] else {
            log.error("Unable to apply unknown theme \(themeName)")
            return
        }
        actionButtonTintColor = theme.buttonTintColor!
    }
}

extension TabToolbar: AppStateDelegate {
    func appDidUpdateState(_ state: AppState) {
        let isPrivate = Accessors.isPrivate(state)
        applyTheme(isPrivate ? Theme.PrivateMode : Theme.NormalMode)

        let showHomepage = !HomePageAccessors.isButtonInMenu(state)
        homePageButton.removeFromSuperview()
        shareButton.removeFromSuperview()

        if showHomepage {
            homePageButton.isEnabled = HomePageAccessors.isButtonEnabled(state)
            addButtons(homePageButton)
        } else {
            addButtons(shareButton)
        }
        updateConstraints()
    }
}
