// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ToolbarKit
import Redux
import UIKit

class NavigationToolbarContainer: UIView, ThemeApplicable, StoreSubscriber {
    typealias SubscriberStateType = BrowserViewControllerState

    private enum UX {
        static let toolbarHeight: CGFloat = 48
    }

    var windowUUID: WindowUUID? {
        didSet {
            subscribeToRedux()
        }
    }
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
        guard let uuid = windowUUID else { return }

        store.subscribe(self, transform: {
            $0.select({ appState in
                return BrowserViewControllerState(appState: appState, uuid: uuid)
            })
        })
    }

    func unsubscribeFromRedux() {
        store.unsubscribe(self)
    }

    func newState(state: BrowserViewControllerState) {
        toolbarState = state.toolbarState
        updateModel(toolbarState: state.toolbarState)
    }

    private func updateModel(toolbarState: ToolbarState) {
        guard let windowUUID else { return }
        let model = NavigationToolbarContainerModel(state: toolbarState, windowUUID: windowUUID)
        self.model = model

        toolbar.configure(state: model.navigationToolbarState)
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
