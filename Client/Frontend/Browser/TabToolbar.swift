/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Shared
import XCGLogger

private let log = Logger.browserLogger

protocol TabToolbarProtocol: class {
    weak var tabToolbarDelegate: TabToolbarDelegate? { get set }
    var tabsButton: TabsButton { get }
    var menuButton: ToolbarButton { get }
    var forwardButton: ToolbarButton { get }
    var backButton: ToolbarButton { get }
    var stopReloadButton: ToolbarButton { get }
    var actionButtons: [Themeable & UIButton] { get }

    func updateBackStatus(_ canGoBack: Bool)
    func updateForwardStatus(_ canGoForward: Bool)
    func updateReloadStatus(_ isLoading: Bool)
    func updatePageStatus(_ isWebPage: Bool)
    func updateTabCount(_ count: Int, animated: Bool)
}

protocol TabToolbarDelegate: class {
    func tabToolbarDidPressBack(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressForward(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressBack(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressForward(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressReload(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressReload(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressStop(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressMenu(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressTabs(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressTabs(_ tabToolbar: TabToolbarProtocol, button: UIButton)
}

@objc
open class TabToolbarHelper: NSObject {
    let toolbar: TabToolbarProtocol

    let ImageReload = UIImage.templateImageNamed("nav-refresh")
    let ImageStop = UIImage.templateImageNamed("nav-stop")

    var loading: Bool = false {
        didSet {
            if loading {
                toolbar.stopReloadButton.setImage(ImageStop, for: .normal)
                toolbar.stopReloadButton.accessibilityLabel = NSLocalizedString("Stop", comment: "Accessibility Label for the tab toolbar Stop button")
            } else {
                toolbar.stopReloadButton.setImage(ImageReload, for: .normal)
                toolbar.stopReloadButton.accessibilityLabel = NSLocalizedString("Reload", comment: "Accessibility Label for the tab toolbar Reload button")
            }
        }
    }

    fileprivate func setTheme(theme: String, forButtons buttons: [Themeable]) {
        buttons.forEach { $0.applyTheme(theme) }
    }

    init(toolbar: TabToolbarProtocol) {
        self.toolbar = toolbar
        super.init()

        toolbar.backButton.setImage(UIImage.templateImageNamed("nav-back"), for: .normal)
        toolbar.backButton.accessibilityLabel = NSLocalizedString("Back", comment: "Accessibility label for the Back button in the tab toolbar.")
        let longPressGestureBackButton = UILongPressGestureRecognizer(target: self, action: #selector(TabToolbarHelper.SELdidLongPressBack(_:)))
        toolbar.backButton.addGestureRecognizer(longPressGestureBackButton)
        toolbar.backButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickBack), for: UIControlEvents.touchUpInside)

        toolbar.forwardButton.setImage(UIImage.templateImageNamed("nav-forward"), for: .normal)
        toolbar.forwardButton.accessibilityLabel = NSLocalizedString("Forward", comment: "Accessibility Label for the tab toolbar Forward button")
        let longPressGestureForwardButton = UILongPressGestureRecognizer(target: self, action: #selector(TabToolbarHelper.SELdidLongPressForward(_:)))
        toolbar.forwardButton.addGestureRecognizer(longPressGestureForwardButton)
        toolbar.forwardButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickForward), for: UIControlEvents.touchUpInside)

        toolbar.stopReloadButton.setImage(UIImage.templateImageNamed("nav-refresh"), for: .normal)
        toolbar.stopReloadButton.accessibilityLabel = NSLocalizedString("Reload", comment: "Accessibility Label for the tab toolbar Reload button")
        let longPressGestureStopReloadButton = UILongPressGestureRecognizer(target: self, action: #selector(TabToolbarHelper.SELdidLongPressStopReload(_:)))
        toolbar.stopReloadButton.addGestureRecognizer(longPressGestureStopReloadButton)
        toolbar.stopReloadButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickStopReload), for: UIControlEvents.touchUpInside)

        toolbar.tabsButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickTabs), for: .touchUpInside)
        let longPressGestureTabsButton = UILongPressGestureRecognizer(target: self, action: #selector(TabToolbarHelper.SELdidLongPressTabs(_:)))
        toolbar.tabsButton.addGestureRecognizer(longPressGestureTabsButton)

        toolbar.menuButton.contentMode = UIViewContentMode.center
        toolbar.menuButton.setImage(UIImage.templateImageNamed("nav-menu"), for: .normal)
        toolbar.menuButton.accessibilityLabel = Strings.AppMenuButtonAccessibilityLabel
        toolbar.menuButton.addTarget(self, action: #selector(TabToolbarHelper.SELdidClickMenu), for: UIControlEvents.touchUpInside)
        toolbar.menuButton.accessibilityIdentifier = "TabToolbar.menuButton"
        setTheme(theme: Theme.NormalMode, forButtons: toolbar.actionButtons)
    }

    func SELdidClickBack() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressBack(toolbar, button: toolbar.backButton)
    }

    func SELdidLongPressBack(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.began {
            toolbar.tabToolbarDelegate?.tabToolbarDidLongPressBack(toolbar, button: toolbar.backButton)
        }
    }

    func SELdidClickTabs() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressTabs(toolbar, button: toolbar.tabsButton)
    }
    
    func SELdidLongPressTabs(_ recognizer: UILongPressGestureRecognizer) {
        toolbar.tabToolbarDelegate?.tabToolbarDidLongPressTabs(toolbar, button: toolbar.tabsButton)
    }

    func SELdidClickForward() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressForward(toolbar, button: toolbar.forwardButton)
    }

    func SELdidLongPressForward(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.began {
            toolbar.tabToolbarDelegate?.tabToolbarDidLongPressForward(toolbar, button: toolbar.forwardButton)
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

    func updateReloadStatus(_ isLoading: Bool) {
        loading = isLoading
    }
}

class ToolbarButton: UIButton {
    static let Themes: [String: Theme] = {
        var themes = [String: Theme]()
        var theme = Theme()
        theme.buttonTintColor = UIColor(rgb: 0xd2d2d4)
        theme.highlightButtonColor = UIColor(rgb: 0xAC39FF)
        theme.disabledButtonColor = UIColor.gray
        themes[Theme.PrivateMode] = theme
        
        theme = Theme()
        theme.buttonTintColor = UIColor(rgb: 0x272727)
        theme.highlightButtonColor = UIColor(rgb: 0x00A2FE)
        theme.disabledButtonColor = UIColor.lightGray
        themes[Theme.NormalMode] = theme
        
        return themes
    }()
    
    var selectedTintColor: UIColor!
    var unselectedTintColor: UIColor!
    var disabledTintColor: UIColor!

    override init(frame: CGRect) {
        super.init(frame: frame)
        adjustsImageWhenHighlighted = false
        selectedTintColor = tintColor
        unselectedTintColor = tintColor
        disabledTintColor = UIColor.gray
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open var isHighlighted: Bool {
        didSet {
            self.tintColor = isHighlighted ? selectedTintColor : unselectedTintColor
        }
    }
    
    override open var isEnabled: Bool {
        didSet {
            self.tintColor = isEnabled ? unselectedTintColor : disabledTintColor
        }
    }

    override var tintColor: UIColor! {
        didSet {
            self.imageView?.tintColor = self.tintColor
        }
    }
    
}

extension ToolbarButton: Themeable {
    func applyTheme(_ themeName: String) {
        guard let theme = ToolbarButton.Themes[themeName] else {
            log.error("Unable to apply unknown theme \(themeName)")
            return
        }
        selectedTintColor = theme.highlightButtonColor
        disabledTintColor = theme.disabledButtonColor
        unselectedTintColor = theme.buttonTintColor
        tintColor = isEnabled ? unselectedTintColor : disabledTintColor
        imageView?.tintColor = tintColor
    }
}

class TabToolbar: Toolbar, TabToolbarProtocol {
    weak var tabToolbarDelegate: TabToolbarDelegate?

    let tabsButton: TabsButton
    let menuButton: ToolbarButton
    let forwardButton: ToolbarButton
    let backButton: ToolbarButton
    let stopReloadButton: ToolbarButton
    let actionButtons: [Themeable & UIButton]

    var helper: TabToolbarHelper?

    static let Themes: [String: Theme] = {
        var themes = [String: Theme]()
        var theme = Theme()
        theme.backgroundColor = UIColor(rgb: 0x38383D)
        themes[Theme.PrivateMode] = theme

        theme = Theme()
        theme.backgroundColor = UIConstants.AppBackgroundColor
        themes[Theme.NormalMode] = theme

        return themes
    }()

    // This has to be here since init() calls it
    fileprivate override init(frame: CGRect) {
        // And these have to be initialized in here or the compiler will get angry
        backButton = ToolbarButton()
        backButton.accessibilityIdentifier = "TabToolbar.backButton"
        forwardButton = ToolbarButton()
        forwardButton.accessibilityIdentifier = "TabToolbar.forwardButton"
        stopReloadButton = ToolbarButton()
        stopReloadButton.accessibilityIdentifier = "TabToolbar.stopReloadButton"
        tabsButton = TabsButton()
        tabsButton.accessibilityIdentifier = "TabToolbar.tabsButton"
        menuButton = ToolbarButton()
        menuButton.accessibilityIdentifier = "TabToolbar.menuButton"
        actionButtons = [backButton, forwardButton, stopReloadButton, tabsButton, menuButton]

        super.init(frame: frame)

        helper = TabToolbarHelper(toolbar: self)
        addButtons(actionButtons)

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

    func updateReloadStatus(_ isLoading: Bool) {
        helper?.updateReloadStatus(isLoading)
    }

    func updatePageStatus(_ isWebPage: Bool) {
        stopReloadButton.isEnabled = isWebPage
    }
    
    func updateTabCount(_ count: Int, animated: Bool) {
        tabsButton.updateTabCount(count, animated: animated)
    }

    override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            drawLine(context, start: CGPoint(x: 0, y: 0), end: CGPoint(x: frame.width, y: 0))
        }
    }

    fileprivate func drawLine(_ context: CGContext, start: CGPoint, end: CGPoint) {
        context.setStrokeColor(UIColor.black.withAlphaComponent(0.05).cgColor)
        context.setLineWidth(2)
        context.move(to: CGPoint(x: start.x, y: start.y))
        context.addLine(to: CGPoint(x: end.x, y: end.y))
        context.strokePath()
    }
}

extension TabToolbar: Themeable {
    func applyTheme(_ themeName: String) {
        guard let theme = TabToolbar.Themes[themeName] else {
            log.error("Unable to apply unknown theme \(themeName)")
            return
        }
        backgroundColor = theme.backgroundColor!
        helper?.setTheme(theme: themeName, forButtons: actionButtons)
    }
}
