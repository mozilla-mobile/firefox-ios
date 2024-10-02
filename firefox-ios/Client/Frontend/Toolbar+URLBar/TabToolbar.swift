// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared
import Account

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

    private let privateModeBadge = BadgeWithBackdrop(
        imageName: StandardImageIdentifiers.Medium.privateModeCircleFillPurple,
        isPrivateBadge: true)
    private let warningMenuBadge = BadgeWithBackdrop(imageName: StandardImageIdentifiers.Large.warningFill,
                                                     imageMask: ImageIdentifiers.menuWarningMask)

    var helper: TabToolbarHelper?
    var isMicrosurveyShown = false
    private let contentView = UIStackView()

    // MARK: - Initializers
    override private init(frame: CGRect) {
        actionButtons = [backButton, forwardButton, multiStateButton, addNewTabButton, tabsButton, appMenuButton]
        super.init(frame: frame)
        setupAccessibility()

        addSubview(contentView)
        helper = TabToolbarHelper(toolbar: self)
        addButtons(actionButtons)

        privateModeBadge.add(toParent: contentView)
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
        // No line when the search bar or microsurvey is on top of the toolbar
        // In terms of the microsurvey, by not having the border, it makes it difficult for websites to replicate the prompt.
        guard !isBottomSearchBar && !isMicrosurveyShown else { return }

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
    func privateModeBadge(visible: Bool) {
        privateModeBadge.show(visible)
    }

    func warningMenuBadge(setVisible: Bool) {
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

    func addUILargeContentViewInteraction(
        interaction: UILargeContentViewerInteraction
    ) {
        addInteraction(interaction)
    }
}

// MARK: - Theme protocols
extension TabToolbar: ThemeApplicable, PrivateModeUI {
    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer1
        actionButtons.forEach { $0.applyTheme(theme: theme) }

        privateModeBadge.badge.tintBackground(color: theme.colors.layer1)
        warningMenuBadge.badge.tintBackground(color: theme.colors.layer1)
    }

    func applyUIMode(isPrivate: Bool, theme: Theme) {
        privateModeBadge(visible: isPrivate)
    }
}
