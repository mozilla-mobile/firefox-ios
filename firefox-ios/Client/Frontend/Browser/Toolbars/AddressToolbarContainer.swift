// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit
import UIKit

protocol AddressToolbarContainerDelegate: AnyObject {
    func searchSuggestions(searchTerm: String)
    func openBrowser(searchTerm: String)
    func openSuggestions(searchTerm: String)
    func addressToolbarContainerAccessibilityActions() -> [UIAccessibilityCustomAction]?
}

final class AddressToolbarContainer: UIView,
                                     ThemeApplicable,
                                     TopBottomInterchangeable,
                                     AlphaDimmable,
                                     StoreSubscriber,
                                     AddressToolbarDelegate,
                                     MenuHelperURLBarInterface {
    typealias SubscriberStateType = ToolbarState

    private var windowUUID: WindowUUID?
    private var profile: Profile?
    private var model: AddressToolbarContainerModel?
    private var delegate: AddressToolbarContainerDelegate?

    private var toolbar: BrowserAddressToolbar {
        let isCompact = traitCollection.horizontalSizeClass == .compact
        return isCompact ? compactToolbar : regularToolbar
    }

    private var isTransitioning = false {
        didSet {
            if isTransitioning {
                // Cancel any pending/in-progress animations related to the progress bar
                self.progressBar.setProgress(1, animated: false)
                self.progressBar.alpha = 0.0
            }
        }
    }

    var parent: UIStackView?
    private lazy var compactToolbar: CompactBrowserAddressToolbar = .build()
    private lazy var regularToolbar: RegularBrowserAddressToolbar = .build()
    private lazy var progressBar: GradientProgressBar = .build { bar in
        bar.clipsToBounds = false
    }

    private var progressBarTopConstraint: NSLayoutConstraint?
    private var progresBarBottomConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(windowUUID: WindowUUID, profile: Profile, delegate: AddressToolbarContainerDelegate) {
        self.windowUUID = windowUUID
        self.profile = profile
        self.delegate = delegate
        subscribeToRedux()
    }

    func updateProgressBar(progress: Double) {
        DispatchQueue.main.async { [unowned self] in
            progressBar.alpha = 1
            progressBar.isHidden = false
            progressBar.setProgress(Float(progress), animated: !isTransitioning)
        }
    }

    func hideProgressBar() {
        progressBar.isHidden = true
        progressBar.setProgress(0, animated: false)
    }

    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        return toolbar.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        return toolbar.resignFirstResponder()
    }

    // MARK: View Transitions
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        adjustLayout()
    }

    // MARK: - Redux

    func subscribeToRedux() {
        guard let windowUUID else { return }

        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.showScreen,
                                  screen: .toolbar)
        store.dispatch(action)

        store.subscribe(self, transform: {
            $0.select({ appState in
                return ToolbarState(appState: appState, uuid: windowUUID)
            })
        })
    }

    func unsubscribeFromRedux() {
        guard let windowUUID else {
            store.unsubscribe(self)
            return
        }

        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.closeScreen,
                                  screen: .toolbar)
        store.dispatch(action)
        store.unsubscribe(self)
    }

    func newState(state: ToolbarState) {
        updateModel(toolbarState: state)
    }

    func updateAlphaForSubviews(_ alpha: CGFloat) {
        // when the user scrolls the webpage the address toolbar gets hidden by changing its alpha
        compactToolbar.alpha = alpha
        regularToolbar.alpha = alpha
    }

    private func updateModel(toolbarState: ToolbarState) {
        guard let windowUUID, let profile else { return }
        let model = AddressToolbarContainerModel(state: toolbarState,
                                                 profile: profile,
                                                 windowUUID: windowUUID)
        if self.model != model {
            self.model = model

        	updateProgressBarPosition(toolbarState.toolbarPosition)
            compactToolbar.configure(state: model.addressToolbarState, toolbarDelegate: self)
            regularToolbar.configure(state: model.addressToolbarState, toolbarDelegate: self)

            if toolbarState.addressToolbar.isEditing {
                _ = becomeFirstResponder()
            } else {
                _ = resignFirstResponder()
            }
        }
    }

    private func setupLayout() {
        addSubview(progressBar)
        adjustLayout()
    }

    private func adjustLayout() {
        compactToolbar.removeFromSuperview()
        regularToolbar.removeFromSuperview()

        addSubview(toolbar)

        NSLayoutConstraint.activate([
            progressBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: trailingAnchor),

            toolbar.topAnchor.constraint(equalTo: topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: bottomAnchor),
            toolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    private func updateProgressBarPosition(_ position: AddressToolbarPosition) {
        progressBarTopConstraint?.isActive = false
        progresBarBottomConstraint?.isActive = false

        switch position {
        case .top:
            progressBarTopConstraint = progressBar.topAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
            progressBarTopConstraint?.isActive = true
        case .bottom:
            progresBarBottomConstraint = progressBar.bottomAnchor.constraint(lessThanOrEqualTo: topAnchor)
            progresBarBottomConstraint?.isActive = true
        }
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        compactToolbar.applyTheme(theme: theme)
        regularToolbar.applyTheme(theme: theme)
        progressBar.setGradientColors(
            startColor: theme.colors.borderAccent,
            middleColor: theme.colors.iconAccentPink,
            endColor: theme.colors.iconAccentYellow
        )
    }

    // MARK: - AddressToolbarDelegate
    func searchSuggestions(searchTerm: String) {
        delegate?.searchSuggestions(searchTerm: searchTerm)
    }

    func openBrowser(searchTerm: String) {
        delegate?.openBrowser(searchTerm: searchTerm)
    }

    func openSuggestions(searchTerm: String) {
        delegate?.openSuggestions(searchTerm: searchTerm)

        guard let windowUUID else { return }

        let action = ToolbarMiddlewareAction(windowUUID: windowUUID,
                                             actionType: ToolbarMiddlewareActionType.didStartEditingUrl)
        store.dispatch(action)
    }

    func addressToolbarAccessibilityActions() -> [UIAccessibilityCustomAction]? {
        delegate?.addressToolbarContainerAccessibilityActions()
    }

    // MARK: - MenuHelperURLBarInterface
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == MenuHelperURLBarModel.selectorPasteAndGo {
            return UIPasteboard.general.hasStrings
        }

        return super.canPerformAction(action, withSender: sender)
    }

    func menuHelperPasteAndGo() {
        guard let pasteboardContents = UIPasteboard.general.string else { return }
        delegate?.openBrowser(searchTerm: pasteboardContents)
    }
}
