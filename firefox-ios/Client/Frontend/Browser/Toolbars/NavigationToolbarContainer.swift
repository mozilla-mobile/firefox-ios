// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ToolbarKit
import Redux
import UIKit

protocol NavigationToolbarContainerDelegate: AnyObject {
    func configureContextualHint(for: UIButton, with contextualHintType: String)
}

final class NavigationToolbarContainer: UIView, ThemeApplicable, StoreSubscriber {
    typealias SubscriberStateType = ToolbarState

    private enum UX {
        static let toolbarHeight: CGFloat = 48
    }

    var windowUUID: WindowUUID? {
        didSet {
            subscribeToRedux()
        }
    }
    weak var toolbarDelegate: NavigationToolbarContainerDelegate?
    private var model: NavigationToolbarContainerModel?

    private lazy var toolbar: BrowserNavigationToolbar =  .build { _ in }
    private var toolbarHeightConstraint: NSLayoutConstraint?

    private var bottomToolbarHeight: CGFloat { return UX.toolbarHeight + UIConstants.BottomInset }

    private var theme: Theme?
    private var isVersion1Layout = false {
        didSet {
            // We need to call applyTheme to ensure the colors are updated in sync whenever the layout changes.
            guard let theme, isVersion1Layout != oldValue else { return }
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

    override func layoutSubviews() {
        super.layoutSubviews()

        // when the layout is setup the window scene is not attached yet so we need to update the constant later
        toolbarHeightConstraint?.constant = bottomToolbarHeight
    }

    // MARK: - Redux

    func subscribeToRedux() {
        guard let windowUUID else { return }

        store.subscribe(self, transform: {
            $0.select({ appState in
                return ToolbarState(appState: appState, uuid: windowUUID)
            })
        })
    }

    func unsubscribeFromRedux() {
        store.unsubscribe(self)
    }

    func newState(state: ToolbarState) {
        updateModel(toolbarState: state)
    }

    private func updateModel(toolbarState: ToolbarState) {
        guard let windowUUID else { return }
        isVersion1Layout = toolbarState.toolbarLayout == .version1
        let model = NavigationToolbarContainerModel(state: toolbarState, windowUUID: windowUUID)

        if self.model != model {
            self.model = model
            toolbar.configure(
                config: model.navigationToolbarConfiguration,
                isVersion1Layout: isVersion1Layout,
                toolbarDelegate: self
            )
        }
    }

    private func setupLayout() {
        addSubview(toolbar)

        toolbarHeightConstraint = heightAnchor.constraint(equalToConstant: bottomToolbarHeight)
        toolbarHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbar.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            toolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        toolbar.applyTheme(theme: theme)
        backgroundColor = isVersion1Layout ? theme.colors.layer3 : theme.colors.layer1
    }
}

extension NavigationToolbarContainer: BrowserNavigationToolbarDelegate {
    func configureContextualHint(for button: UIButton, with contextualHintType: String) {
        guard let toolbarState = store.state.screenState(ToolbarState.self, for: .toolbar, window: windowUUID)
        else { return }

        if contextualHintType == ContextualHintType.navigation.rawValue && !toolbarState.canShowNavigationHint { return }

        toolbarDelegate?.configureContextualHint(for: button, with: contextualHintType)
    }
}
