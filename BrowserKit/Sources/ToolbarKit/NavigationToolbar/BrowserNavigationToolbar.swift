// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

public protocol BrowserNavigationToolbarDelegate: AnyObject {
    func configureContextualHint(for button: UIButton, with contextualHintType: String)
}

/// Navigation toolbar implementation.
public class BrowserNavigationToolbar: UIView, NavigationToolbar, ThemeApplicable {
    private enum UX {
        static let horizontalEdgeSpace: CGFloat = 16
        static let buttonSize = CGSize(width: 48, height: 48)
        static let borderHeight: CGFloat = 1
    }

    private weak var toolbarDelegate: BrowserNavigationToolbarDelegate?
    private lazy var actionStack: UIStackView = .build { view in
        view.distribution = .equalSpacing
    }
    private lazy var toolbarBorderView: UIView = .build()
    private var toolbarBorderHeightConstraint: NSLayoutConstraint?
    private var theme: Theme?

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(state: NavigationToolbarState, toolbarDelegate: BrowserNavigationToolbarDelegate) {
        self.toolbarDelegate = toolbarDelegate

        updateActionStack(toolbarElements: state.actions)

        // Update border
        toolbarBorderHeightConstraint?.constant = state.shouldDisplayBorder ? UX.borderHeight : 0
    }

    // MARK: - Private
    private func setupLayout() {
        addSubview(toolbarBorderView)
        addSubview(actionStack)

        toolbarBorderHeightConstraint = toolbarBorderView.heightAnchor.constraint(equalToConstant: 0)
        toolbarBorderHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            toolbarBorderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbarBorderView.topAnchor.constraint(equalTo: topAnchor),
            toolbarBorderView.trailingAnchor.constraint(equalTo: trailingAnchor),

            actionStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.horizontalEdgeSpace),
            actionStack.topAnchor.constraint(equalTo: toolbarBorderView.bottomAnchor),
            actionStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            actionStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.horizontalEdgeSpace),
        ])

        setupAccessibility()
    }

    private func setupAccessibility() {
        addInteraction(UILargeContentViewerInteraction())
    }

    private func updateActionStack(toolbarElements: [ToolbarElement]) {
        actionStack.removeAllArrangedViews()
        toolbarElements.forEach { toolbarElement in
            let button = toolbarElement.numberOfTabs != nil ? TabNumberButton() : ToolbarButton()
            button.configure(element: toolbarElement)
            actionStack.addArrangedSubview(button)

            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: UX.buttonSize.width),
                button.heightAnchor.constraint(equalToConstant: UX.buttonSize.height),
            ])

            if let theme {
                // As we recreate the buttons we need to apply the theme for them to be displayed correctly
                button.applyTheme(theme: theme)
            }

            if let contextualHintType = toolbarElement.contextualHintType {
                toolbarDelegate?.configureContextualHint(for: button, with: contextualHintType)
            }
        }
    }

    // MARK: - ThemeApplicable
    public func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer1
        toolbarBorderView.backgroundColor = theme.colors.borderPrimary

        actionStack.arrangedSubviews.forEach { element in
            guard let button = element as? ToolbarButton else { return }
            button.applyTheme(theme: theme)
        }

        self.theme = theme
    }
}
