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
    func configureContextualHint(for button: UIButton, with contextualHintType: String)
    func addressToolbarDidBeginEditing(searchTerm: String, shouldShowSuggestions: Bool)
    func addressToolbarContainerAccessibilityActions() -> [UIAccessibilityCustomAction]?
    func addressToolbarDidEnterOverlayMode(_ view: UIView)
    func addressToolbar(_ view: UIView, didLeaveOverlayModeForReason: URLBarLeaveOverlayModeReason)
    func addressToolbarDidBeginDragInteraction()
    func addressToolbarDidTapSearchEngine(_ searchEngineView: UIView)
}

final class AddressToolbarContainer: UIView,
                                     ThemeApplicable,
                                     TopBottomInterchangeable,
                                     AlphaDimmable,
                                     StoreSubscriber,
                                     AddressToolbarDelegate,
                                     Autocompletable,
                                     URLBarViewProtocol {
    private enum UX {
        static let toolbarHorizontalPadding: CGFloat = 16
    }

    typealias SubscriberStateType = ToolbarState

    private var windowUUID: WindowUUID?
    private var profile: Profile?
    private var model: AddressToolbarContainerModel?
    private(set) weak var delegate: AddressToolbarContainerDelegate?

    // FXIOS-10210 Temporary to support updating the Unified Search feature flag during runtime
    public var isUnifiedSearchEnabled = false {
        didSet {
            guard oldValue != isUnifiedSearchEnabled else { return }

            compactToolbar.isUnifiedSearchEnabled = isUnifiedSearchEnabled
            regularToolbar.isUnifiedSearchEnabled = isUnifiedSearchEnabled
        }
    }

    private var toolbar: BrowserAddressToolbar {
        return shouldDisplayCompact ? compactToolbar : regularToolbar
    }

    private var searchTerm = ""
    private var shouldDisplayCompact = true
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
    private var progressBarBottomConstraint: NSLayoutConstraint?

    private func calculateToolbarSpace() -> CGFloat {
        // Provide 0 padding in iPhone landscape due to safe area insets
        return shouldDisplayCompact || UIDevice.current.userInterfaceIdiom == .pad ? UX.toolbarHorizontalPadding : 0
    }

    /// Overlay mode is the state where the lock/reader icons are hidden, the home panels are shown,
    /// and the Cancel button is visible (allowing the user to leave overlay mode).
    var inOverlayMode = false

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        windowUUID: WindowUUID,
        profile: Profile,
        delegate: AddressToolbarContainerDelegate,
        isUnifiedSearchEnabled: Bool
    ) {
        self.windowUUID = windowUUID
        self.profile = profile
        self.delegate = delegate
        self.isUnifiedSearchEnabled = isUnifiedSearchEnabled
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
        let newModel = AddressToolbarContainerModel(state: toolbarState,
                                                    profile: profile,
                                                    windowUUID: windowUUID)

        shouldDisplayCompact = newModel.shouldDisplayCompact
        if self.model != newModel {
            // in case we are in edit mode but overlay is not active yet we have to activate it
            // so that `inOverlayMode` is set to true so we avoid getting stuck in overlay mode
            if newModel.isEditing, !inOverlayMode {
                enterOverlayMode(nil, pasted: false, search: true)
            }

            updateProgressBarPosition(toolbarState.toolbarPosition)
            compactToolbar.configure(state: newModel.addressToolbarState,
                                     toolbarDelegate: self,
                                     leadingSpace: calculateToolbarSpace(),
                                     trailingSpace: calculateToolbarSpace(),
                                     isUnifiedSearchEnabled: isUnifiedSearchEnabled)
            regularToolbar.configure(state: newModel.addressToolbarState,
                                     toolbarDelegate: self,
                                     leadingSpace: calculateToolbarSpace(),
                                     trailingSpace: calculateToolbarSpace(),
                                     isUnifiedSearchEnabled: isUnifiedSearchEnabled)

            // the layout (compact/regular) that should be displayed is driven by the state
            // but we only need to switch toolbars if shouldDisplayCompact changes
            // otherwise we needlessly add/remove toolbars from the view hierarchy,
            // which messes with the LocationTextField first responder status
            // (see https://github.com/mozilla-mobile/firefox-ios/issues/21676)
            let shouldSwitchToolbars = newModel.shouldDisplayCompact != self.model?.shouldDisplayCompact

            // Replace the old model after we are done using it for comparison
            // All functionality that depends on the new model should come after this
            self.model = newModel

            if shouldSwitchToolbars {
                switchToolbars()
                guard model?.shouldSelectSearchTerm == false else { return }
                store.dispatch(
                    ToolbarAction(
                        searchTerm: searchTerm,
                        windowUUID: windowUUID,
                        actionType: ToolbarActionType.didSetSearchTerm
                    )
                )
            }
        }
    }

    private func setupLayout() {
        addSubview(progressBar)

        NSLayoutConstraint.activate([
            progressBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        setupToolbarConstraints()
    }

    private func switchToolbars() {
        if compactToolbar.isDescendant(of: self) {
            compactToolbar.removeFromSuperview()
        } else {
            regularToolbar.removeFromSuperview()
        }

        setupToolbarConstraints()
    }

    private func setupToolbarConstraints() {
        addSubview(toolbar)

        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: bottomAnchor),
            toolbar.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    private func updateProgressBarPosition(_ position: AddressToolbarPosition) {
        progressBarTopConstraint?.isActive = false
        progressBarBottomConstraint?.isActive = false

        switch position {
        case .top:
            progressBarTopConstraint = progressBar.topAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
            progressBarTopConstraint?.isActive = true
        case .bottom:
            progressBarBottomConstraint = progressBar.bottomAnchor.constraint(lessThanOrEqualTo: topAnchor)
            progressBarBottomConstraint?.isActive = true
        }
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        compactToolbar.applyTheme(theme: theme)
        regularToolbar.applyTheme(theme: theme)

        let isPrivateMode = model?.isPrivateMode ?? false
        let gradientStartColor = isPrivateMode ? theme.colors.borderAccentPrivate : theme.colors.borderAccent
        let gradientMiddleColor = isPrivateMode ? nil : theme.colors.iconAccentPink
        let gradientEndColor = isPrivateMode ? theme.colors.borderAccentPrivate : theme.colors.iconAccentYellow

        progressBar.setGradientColors(
            startColor: gradientStartColor,
            middleColor: gradientMiddleColor,
            endColor: gradientEndColor
        )
    }

    // MARK: - AddressToolbarDelegate
    func searchSuggestions(searchTerm: String) {
        if let windowUUID,
           let toolbarState = store.state.screenState(ToolbarState.self, for: .toolbar, window: windowUUID) {
            if searchTerm.isEmpty, !toolbarState.addressToolbar.showQRPageAction {
                let action = ToolbarAction(windowUUID: windowUUID, actionType: ToolbarActionType.didDeleteSearchTerm)
                store.dispatch(action)
            } else if !searchTerm.isEmpty, toolbarState.addressToolbar.showQRPageAction {
                let action = ToolbarAction(windowUUID: windowUUID, actionType: ToolbarActionType.didEnterSearchTerm)
                store.dispatch(action)
            } else if !toolbarState.addressToolbar.didStartTyping {
                let action = ToolbarAction(windowUUID: windowUUID, actionType: ToolbarActionType.didStartTyping)
                store.dispatch(action)
            }
        }
        self.searchTerm = searchTerm
        delegate?.searchSuggestions(searchTerm: searchTerm)
    }

    func didClearSearch() {
        searchTerm = ""
        delegate?.searchSuggestions(searchTerm: "")

        guard let windowUUID else { return }

        let action = ToolbarMiddlewareAction(windowUUID: windowUUID,
                                             actionType: ToolbarMiddlewareActionType.didClearSearch)
        store.dispatch(action)
    }

    func openBrowser(searchTerm: String) {
        delegate?.openBrowser(searchTerm: searchTerm)
    }

    func addressToolbarDidTapSearchEngine(_ searchEngineView: UIView) {
        delegate?.addressToolbarDidTapSearchEngine(searchEngineView)
    }

    func addressToolbarDidBeginEditing(searchTerm: String, shouldShowSuggestions: Bool) {
        let locationText = shouldShowSuggestions ? searchTerm : nil
        enterOverlayMode(locationText, pasted: false, search: false)

        if shouldShowSuggestions {
            delegate?.openSuggestions(searchTerm: locationText ?? "")
        }
    }

    func addressToolbarAccessibilityActions() -> [UIAccessibilityCustomAction]? {
        delegate?.addressToolbarContainerAccessibilityActions()
    }

    func configureContextualHint(
        _ addressToolbar: BrowserAddressToolbar,
        for button: UIButton,
        with contextualHintType: String
    ) {
        guard addressToolbar == toolbar,
              let toolbarState = store.state.screenState(ToolbarState.self, for: .toolbar, window: windowUUID)
        else { return }

        if contextualHintType == ContextualHintType.navigation.rawValue && !toolbarState.canShowNavigationHint { return }

        delegate?.configureContextualHint(for: button, with: contextualHintType)
    }

    func addressToolbarDidProvideItemsForDragInteraction() {
        guard let windowUUID else { return }

        let action = ToolbarMiddlewareAction(windowUUID: windowUUID,
                                             actionType: ToolbarMiddlewareActionType.didStartDragInteraction)
        store.dispatch(action)
    }

    func addressToolbarDidBeginDragInteraction() {
        delegate?.addressToolbarDidBeginDragInteraction()
    }

    func addressToolbarNeedsSearchReset() {
        delegate?.searchSuggestions(searchTerm: "")
    }

    // MARK: - Autocompletable
    func setAutocompleteSuggestion(_ suggestion: String?) {
        toolbar.setAutocompleteSuggestion(suggestion)
    }

    // MARK: - Overlay Mode
    func enterOverlayMode(_ locationText: String?, pasted: Bool, search: Bool) {
        guard let windowUUID else { return }
        inOverlayMode = true
        delegate?.addressToolbarDidEnterOverlayMode(self)

        if pasted {
            let action = ToolbarAction(
                searchTerm: locationText,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.didPasteSearchTerm
            )
            store.dispatch(action)

            delegate?.openSuggestions(searchTerm: locationText ?? "")
        } else {
            let action = ToolbarAction(searchTerm: locationText,
                                       windowUUID: windowUUID,
                                       actionType: ToolbarActionType.didStartEditingUrl)
            store.dispatch(action)
        }
    }

    func leaveOverlayMode(reason: URLBarLeaveOverlayModeReason, shouldCancelLoading cancel: Bool) {
        guard let windowUUID,
              let toolbarState = store.state.screenState(ToolbarState.self, for: .toolbar, window: windowUUID)
        else { return }

        _ = toolbar.resignFirstResponder()
        inOverlayMode = false
        delegate?.addressToolbar(self, didLeaveOverlayModeForReason: reason)

        if toolbarState.addressToolbar.isEditing {
            let action = ToolbarAction(windowUUID: windowUUID, actionType: ToolbarActionType.cancelEdit)
            store.dispatch(action)
        }
    }
}
