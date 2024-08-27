// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ToolbarKit
import Redux
import UIKit

protocol NavigationToolbarContainerDelegate: AnyObject {
    func configureContextualHint(for: UIButton)
}

class NavigationToolbarContainer: UIView, ThemeApplicable, StoreSubscriber {
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
    private var toolbarState: ToolbarState?
    private var model: NavigationToolbarContainerModel?

    private lazy var toolbar: BrowserNavigationToolbar =  .build { _ in }
    private var toolbarHeightConstraint: NSLayoutConstraint?

    private var bottomToolbarHeight: CGFloat { return UX.toolbarHeight + UIConstants.BottomInset }

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
        let model = NavigationToolbarContainerModel(state: toolbarState, windowUUID: windowUUID)

        if self.model != model {
            self.model = model
            toolbar.configure(state: model.navigationToolbarState, toolbarDelegate: self)
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
        backgroundColor = theme.colors.layer1
    }
}

extension NavigationToolbarContainer: BrowserNavigationToolbarDelegate {
    func configureContextualHint(for button: UIButton) {
        toolbarDelegate?.configureContextualHint(for: button)
    }
}
