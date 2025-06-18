// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

public protocol BrowserNavigationToolbarDelegate: AnyObject {
    func configureContextualHint(for button: UIButton, with contextualHintType: String)
}

extension UIStackView: BackgroundEffectLayerView {
}

/// Navigation toolbar implementation.
public final class BrowserNavigationToolbar: UIView, NavigationToolbar, ThemeApplicable {
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
    private var isTranslucent = false {
        didSet {
            // We need to call applyTheme to ensure the colors are updated in sync whenever the translucency changes.
            guard let theme, isTranslucent != oldValue else { return }
            applyTheme(theme: theme)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(
        config: NavigationToolbarConfiguration,
        toolbarDelegate: BrowserNavigationToolbarDelegate
    ) {
        self.toolbarDelegate = toolbarDelegate
        self.isTranslucent = config.isTranslucencyEnabled
        updateActionStack(config: config)

        // Update border
        toolbarBorderHeightConstraint?.constant = config.shouldDisplayBorder ? UX.borderHeight : 0
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

    private func updateActionStack(config: NavigationToolbarConfiguration) {
        actionStack.removeAllArrangedViews()
        actionStack.removeAllSubViews()

        let ux = config.uxConfiguration

        if !ux.buttonsEqualSpacing {
            actionStack.applyEffect(cornerRadius: 24.0, isInteractive: false)
        }
        actionStack.isLayoutMarginsRelativeArrangement = true
        actionStack.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 12.0,
            leading: 12.0,
            bottom: 12.0,
            trailing: 12.0
        )

        config.actions.forEach { toolbarElement in
            let button = toolbarElement.numberOfTabs != nil ? TabNumberButton() : ToolbarButton()
            button.configure(element: toolbarElement)
            actionStack.addArrangedSubview(button)

            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: ux.buttonsSize),
                button.heightAnchor.constraint(equalToConstant: ux.buttonsSize),
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
//        backgroundColor = isTranslucent ? .clear : theme.colors.layer3
//        toolbarBorderView.backgroundColor = theme.colors.borderPrimary

        actionStack.arrangedSubviews.forEach { element in
            guard let button = element as? ToolbarButton else { return }
            button.applyTheme(theme: theme)
        }

        self.theme = theme
    }
}
