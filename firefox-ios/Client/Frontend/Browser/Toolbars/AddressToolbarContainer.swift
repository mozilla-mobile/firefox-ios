// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit
import UIKit

class AddressToolbarContainer: UIView, ThemeApplicable, TopBottomInterchangeable, StoreSubscriber {
    typealias SubscriberStateType = BrowserViewControllerState

    var windowUUID: WindowUUID? {
        didSet {
            subscribeToRedux()
        }
    }
    private var toolbarState: ToolbarState?
    private var model: AddressToolbarContainerModel?

    var parent: UIStackView?
    private lazy var compactToolbar: CompactBrowserAddressToolbar =  .build { _ in }
    private lazy var regularToolbar: RegularBrowserAddressToolbar = .build()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ model: AddressToolbarContainerModel,
                   toolbarDelegate: AddressToolbarDelegate) {
        compactToolbar.configure(state: model.addressToolbarState, toolbarDelegate: toolbarDelegate)
        regularToolbar.configure(state: model.addressToolbarState, toolbarDelegate: toolbarDelegate)
    }

    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        let isCompact = traitCollection.horizontalSizeClass == .compact
        let toolbar = isCompact ? compactToolbar : regularToolbar
        return toolbar.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        let isCompact = traitCollection.horizontalSizeClass == .compact
        let toolbar = isCompact ? compactToolbar : regularToolbar
        return toolbar.resignFirstResponder()
    }

    // MARK: View Transitions
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        adjustLayout()
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
        let model = AddressToolbarContainerModel(state: toolbarState, windowUUID: windowUUID)
        self.model = model

        compactToolbar.configure(state: model.addressToolbarState)
        regularToolbar.configure(state: model.addressToolbarState)
    }

    private func setupLayout() {
        adjustLayout()
    }

    private func adjustLayout() {
        compactToolbar.removeFromSuperview()
        regularToolbar.removeFromSuperview()

        let isCompact = traitCollection.horizontalSizeClass == .compact
        let toolbarToAdd = isCompact ? compactToolbar : regularToolbar

        addSubview(toolbarToAdd)

        NSLayoutConstraint.activate([
            toolbarToAdd.topAnchor.constraint(equalTo: topAnchor),
            toolbarToAdd.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbarToAdd.bottomAnchor.constraint(equalTo: bottomAnchor),
            toolbarToAdd.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        compactToolbar.applyTheme(theme: theme)
        regularToolbar.applyTheme(theme: theme)
    }
}
