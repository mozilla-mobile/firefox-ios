/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import Shared

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

@objcMembers
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

    fileprivate func setTheme(theme: Theme, forButtons buttons: [Themeable]) {
        buttons.forEach { $0.applyTheme(theme) }
    }

    init(toolbar: TabToolbarProtocol) {
        self.toolbar = toolbar
        super.init()

        toolbar.backButton.setImage(UIImage.templateImageNamed("nav-back"), for: .normal)
        toolbar.backButton.accessibilityLabel = NSLocalizedString("Back", comment: "Accessibility label for the Back button in the tab toolbar.")
        let longPressGestureBackButton = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressBack))
        toolbar.backButton.addGestureRecognizer(longPressGestureBackButton)
        toolbar.backButton.addTarget(self, action: #selector(didClickBack), for: .touchUpInside)

        toolbar.forwardButton.setImage(UIImage.templateImageNamed("nav-forward"), for: .normal)
        toolbar.forwardButton.accessibilityLabel = NSLocalizedString("Forward", comment: "Accessibility Label for the tab toolbar Forward button")
        let longPressGestureForwardButton = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressForward))
        toolbar.forwardButton.addGestureRecognizer(longPressGestureForwardButton)
        toolbar.forwardButton.addTarget(self, action: #selector(didClickForward), for: .touchUpInside)

        toolbar.stopReloadButton.setImage(UIImage.templateImageNamed("nav-refresh"), for: .normal)
        toolbar.stopReloadButton.accessibilityLabel = NSLocalizedString("Reload", comment: "Accessibility Label for the tab toolbar Reload button")
        let longPressGestureStopReloadButton = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressStopReload))
        toolbar.stopReloadButton.addGestureRecognizer(longPressGestureStopReloadButton)
        toolbar.stopReloadButton.addTarget(self, action: #selector(didClickStopReload), for: .touchUpInside)

        toolbar.tabsButton.addTarget(self, action: #selector(didClickTabs), for: .touchUpInside)
        let longPressGestureTabsButton = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressTabs))
        toolbar.tabsButton.addGestureRecognizer(longPressGestureTabsButton)

        toolbar.menuButton.contentMode = .center
        toolbar.menuButton.setImage(UIImage.templateImageNamed("nav-menu"), for: .normal)
        toolbar.menuButton.accessibilityLabel = Strings.AppMenuButtonAccessibilityLabel
        toolbar.menuButton.addTarget(self, action: #selector(didClickMenu), for: .touchUpInside)
        toolbar.menuButton.accessibilityIdentifier = "TabToolbar.menuButton"
        setTheme(theme: .Normal, forButtons: toolbar.actionButtons)
    }

    func didClickBack() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressBack(toolbar, button: toolbar.backButton)
    }

    func didLongPressBack(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            toolbar.tabToolbarDelegate?.tabToolbarDidLongPressBack(toolbar, button: toolbar.backButton)
        }
    }

    func didClickTabs() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressTabs(toolbar, button: toolbar.tabsButton)
    }
    
    func didLongPressTabs(_ recognizer: UILongPressGestureRecognizer) {
        toolbar.tabToolbarDelegate?.tabToolbarDidLongPressTabs(toolbar, button: toolbar.tabsButton)
    }

    func didClickForward() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressForward(toolbar, button: toolbar.forwardButton)
    }

    func didLongPressForward(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            toolbar.tabToolbarDelegate?.tabToolbarDidLongPressForward(toolbar, button: toolbar.forwardButton)
        }
    }

    func didClickMenu() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressMenu(toolbar, button: toolbar.menuButton)
    }

    func didClickStopReload() {
        if loading {
            toolbar.tabToolbarDelegate?.tabToolbarDidPressStop(toolbar, button: toolbar.stopReloadButton)
        } else {
            toolbar.tabToolbarDelegate?.tabToolbarDidPressReload(toolbar, button: toolbar.stopReloadButton)
        }
    }

    func didLongPressStopReload(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began && !loading {
            toolbar.tabToolbarDelegate?.tabToolbarDidLongPressReload(toolbar, button: toolbar.stopReloadButton)
        }
    }

    func updateReloadStatus(_ isLoading: Bool) {
        loading = isLoading
    }
}

class ToolbarButton: UIButton {
    var selectedTintColor: UIColor!
    var unselectedTintColor: UIColor!
    var disabledTintColor: UIColor!

    override init(frame: CGRect) {
        super.init(frame: frame)
        adjustsImageWhenHighlighted = false
        selectedTintColor = tintColor
        unselectedTintColor = tintColor
        disabledTintColor = UIColor.gray
        imageView?.contentMode = .scaleAspectFit
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
    func applyTheme(_ theme: Theme) {
        selectedTintColor = UIColor.ToolbarButton.SelectedTint.colorFor(theme)
        disabledTintColor = UIColor.ToolbarButton.DisabledTint.colorFor(theme)
        unselectedTintColor = UIColor.Browser.Tint.colorFor(theme)
        tintColor = isEnabled ? unselectedTintColor : disabledTintColor
        imageView?.tintColor = tintColor
    }
}

class TabToolbar: UIView {
    weak var tabToolbarDelegate: TabToolbarDelegate?

    let tabsButton = TabsButton()
    let menuButton = ToolbarButton()
    let forwardButton = ToolbarButton()
    let backButton = ToolbarButton()
    let stopReloadButton = ToolbarButton()
    let actionButtons: [Themeable & UIButton]

    var helper: TabToolbarHelper?
    private let contentView = UIStackView()

    fileprivate override init(frame: CGRect) {
        actionButtons = [backButton, forwardButton, stopReloadButton, tabsButton, menuButton]
        super.init(frame: frame)
        setupAccessibility()

        addSubview(contentView)
        helper = TabToolbarHelper(toolbar: self)
        addButtons(actionButtons)
        contentView.axis = .horizontal
        contentView.distribution = .fillEqually
    }

    override func updateConstraints() {
        contentView.snp.makeConstraints { make in
            make.leading.trailing.top.equalTo(self)
            make.bottom.equalTo(self.safeArea.bottom)
        }
        super.updateConstraints()
    }

    private func setupAccessibility() {
        backButton.accessibilityIdentifier = "TabToolbar.backButton"
        forwardButton.accessibilityIdentifier = "TabToolbar.forwardButton"
        stopReloadButton.accessibilityIdentifier = "TabToolbar.stopReloadButton"
        tabsButton.accessibilityIdentifier = "TabToolbar.tabsButton"
        menuButton.accessibilityIdentifier = "TabToolbar.menuButton"
        accessibilityNavigationStyle = .combined
        accessibilityLabel = NSLocalizedString("Navigation Toolbar", comment: "Accessibility label for the navigation toolbar displayed at the bottom of the screen.")
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addButtons(_ buttons: [UIButton]) {
        buttons.forEach { contentView.addArrangedSubview($0) }
    }

    override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            drawLine(context, start: .zero, end: CGPoint(x: frame.width, y: 0))
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

extension TabToolbar: TabToolbarProtocol {
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
}

extension TabToolbar: Themeable {
    func applyTheme(_ theme: Theme) {
        backgroundColor = UIColor.Browser.Background.colorFor(theme)
        helper?.setTheme(theme: theme, forButtons: actionButtons)
    }
}
