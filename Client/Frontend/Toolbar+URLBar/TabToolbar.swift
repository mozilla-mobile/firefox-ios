// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

class TabToolbar: UIView, SearchBarLocationProvider {
    // MARK: - Variables

    weak var tabToolbarDelegate: TabToolbarDelegate?

    let tabsButton = TabsButton()
    let addNewTabButton = ToolbarButton()
    let appMenuButton = ToolbarButton()
    let bookmarksButton = ToolbarButton()
    let forwardButton = ToolbarButton()
    let backButton = ToolbarButton()
    let multiStateButton = ToolbarButton()
    let actionButtons: [ThemeApplicable & UIButton]

    private let privateModeBadge = BadgeWithBackdrop(imageName: ImageIdentifiers.privateModeBadge,
                                                     isPrivateBadge: true)
    private let appMenuBadge = BadgeWithBackdrop(imageName: ImageIdentifiers.menuBadge)
    private let warningMenuBadge = BadgeWithBackdrop(imageName: ImageIdentifiers.menuWarning,
                                                     imageMask: ImageIdentifiers.menuWarningMask)

    var helper: TabToolbarHelper?
    private let contentView = UIStackView()

    // MARK: - Initializers
    private override init(frame: CGRect) {
        actionButtons = [backButton, forwardButton, multiStateButton, addNewTabButton, tabsButton, appMenuButton]
        super.init(frame: frame)
        setupAccessibility()

        addSubview(contentView)
        helper = TabToolbarHelper(toolbar: self)
        addButtons(actionButtons)

        privateModeBadge.add(toParent: contentView)
        appMenuBadge.add(toParent: contentView)
        warningMenuBadge.add(toParent: contentView)

        contentView.axis = .horizontal
        contentView.distribution = .fillEqually
        contentView.translatesAutoresizingMaskIntoConstraints = false
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Setup

    override func updateConstraints() {
        privateModeBadge.layout(onButton: tabsButton)
        appMenuBadge.layout(onButton: appMenuButton)
        warningMenuBadge.layout(onButton: appMenuButton)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
        ])
        super.updateConstraints()
    }

    private func setupAccessibility() {
        backButton.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.backButton
        forwardButton.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.forwardButton
        tabsButton.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.tabsButton
        addNewTabButton.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.addNewTabButton
        appMenuButton.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.settingsMenuButton
        accessibilityNavigationStyle = .combined
        accessibilityLabel = .TabToolbarNavigationToolbarAccessibilityLabel
    }

    func addButtons(_ buttons: [UIButton]) {
        buttons.forEach { contentView.addArrangedSubview($0) }
    }

    override func draw(_ rect: CGRect) {
        // No line when the search bar is on top of the toolbar
        guard !isBottomSearchBar else { return }

        if let context = UIGraphicsGetCurrentContext() {
            drawLine(context, start: .zero, end: CGPoint(x: frame.width, y: 0))
        }
    }

    private func drawLine(_ context: CGContext, start: CGPoint, end: CGPoint) {
        context.setStrokeColor(UIColor.black.withAlphaComponent(0.05).cgColor)
        context.setLineWidth(2)
        context.move(to: CGPoint(x: start.x, y: start.y))
        context.addLine(to: CGPoint(x: end.x, y: end.y))
        context.strokePath()
    }
}

// MARK: - TabToolbarProtocol
extension TabToolbar: TabToolbarProtocol {
    var homeButton: ToolbarButton { multiStateButton }

    func privateModeBadge(visible: Bool) {
        privateModeBadge.show(visible)
    }

    func warningMenuBadge(setVisible: Bool) {
        // Disable other menu badges before showing the warning.
        if !appMenuBadge.badge.isHidden { appMenuBadge.show(false) }
        warningMenuBadge.show(setVisible)
    }

    func updateBackStatus(_ canGoBack: Bool) {
        backButton.isEnabled = canGoBack
    }

    func updateForwardStatus(_ canGoForward: Bool) {
        forwardButton.isEnabled = canGoForward
    }

    func updateMiddleButtonState(_ state: MiddleButtonState) {
        helper?.setMiddleButtonState(state)
    }

    func updatePageStatus(_ isWebPage: Bool) { }

    func updateTabCount(_ count: Int, animated: Bool) {
        tabsButton.updateTabCount(count, animated: animated)
    }
}

// MARK: - Theme protocols
extension TabToolbar: ThemeApplicable, PrivateModeUI {
    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer1
        actionButtons.forEach { $0.applyTheme(theme: theme) }

        privateModeBadge.badge.tintBackground(color: theme.colors.layer1)
        appMenuBadge.badge.tintBackground(color: theme.colors.layer1)
        warningMenuBadge.badge.tintBackground(color: theme.colors.layer1)
    }

    func applyUIMode(isPrivate: Bool, theme: Theme) {
        privateModeBadge(visible: isPrivate)
    }
}
